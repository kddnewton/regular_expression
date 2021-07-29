# frozen_string_literal: true

module RegularExpression
  module Compiler
    module Cranelift
      # A return status that indicates that the input string did not match the
      # state machine
      MATCHING_FAILED = 0

      # A return status that indicates that the input string contained an
      # uncommon pattern that we had already optimized away, so we need to
      # deoptimize and fall back to the interpreter
      MATCHING_DEOPTIMIZE = 1

      # A return status that indicates that the input string matched the state
      # machine
      MATCHING_SUCCESS = 2
      class Compiled
        attr_reader :f_ptr, :f_size, :captures

        def initialize(f_ptr, f_size, captures)
          @f_ptr = f_ptr
          @f_size = f_size
          @captures = captures
        end

        def disasm
          output = StringIO.new

          crabstone = Crabstone::Disassembler.new(Crabstone::ARCH_X86, Crabstone::MODE_64)
          ptr = Fiddle::Pointer.new(f_ptr)
          crabstone.disasm(ptr[0, f_size], f_ptr).each do |insn|
            output.printf(
              "0x%<address>x:\t%<instruction>s\t%<details>s\n",
              address: insn.address,
              instruction: insn.mnemonic,
              details: insn.op_str
            )
          end

          output.string
        end

        def to_proc
          indices = ([-1] * (captures.length * 2)).pack("q*")
          function = Fiddle::Function.new(
            @f_ptr,
            [Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T, Fiddle::TYPE_VOIDP],
            Fiddle::TYPE_INT8_T
          )
          lambda do |string|
            value = function.call(string, string.length, indices)
            case value
            when MATCHING_FAILED
              nil
            when MATCHING_DEOPTIMIZE
              raise Pattern::Deoptimize
            when MATCHING_SUCCESS
              indices.unpack("q*")
            else
              raise
            end
          end
        end
      end

      def self.jump_to_next_block(bcx)
        block = bcx.create_block
        bcx.jump(block, [])
        bcx.switch_to_block(block)
      end

      def self.compile(cfg, schedule)
        b = CraneliftRuby::CraneliftBuilder.new
        s = b.make_signature(%i[I64 I64 I64], [:I8])
        external_func_sig = b.make_signature([:I8], [:I64])
        f = b.make_function("regex", s, lambda { |bcx|
          external_func_sigref = bcx.import_signature(external_func_sig)
          initial_block = bcx.create_block
          exit_block = bcx.create_block
          bcx.append_block_params_for_function_params(initial_block)
          bcx.switch_to_block(initial_block)

          string_pointer = bcx.block_param(initial_block, 0)
          string_length = bcx.block_param(initial_block, 1)
          captures_pointer = bcx.block_param(initial_block, 2)

          match_index = CraneliftRuby::Variable.new(0)
          bcx.declare_var(match_index, :I64)
          zero = bcx.iconst(:I64, 0)
          one = bcx.iconst(:I64, 1)
          bcx.def_var(match_index, zero)

          string_index = CraneliftRuby::Variable.new(1)
          bcx.declare_var(string_index, :I64)

          flag = CraneliftRuby::Variable.new(2)
          bcx.declare_var(flag, :I64)
          bcx.def_var(flag, zero)

          variables = []
          cfg.backtracks.times do |i|
            var = CraneliftRuby::Variable.new(3 + i)
            bcx.declare_var(var, :I64)
            variables << var
          end

          # start of our loop, check if we finished looking through the string
          start_loop_head = bcx.create_block
          bcx.jump(start_loop_head, [])
          bcx.switch_to_block(start_loop_head)
          match_index_val = bcx.use_var(match_index)
          bcx.br_icmp(:sg, match_index_val, string_length, exit_block, [])
          bcx.def_var(string_index, match_index_val)
          block_map = {}

          schedule.each do |block|
            block_map[block.name] = bcx.create_block
          end
          bcx.jump(block_map[schedule[0].name], [])
          schedule.each do |block|
            bcx.switch_to_block(block_map[block.name])
            block.insns.each do |insn|
              case insn
              when Bytecode::Insns::PushIndex
                var = variables[insn.index]
                string_index_val = bcx.use_var(string_index)
                bcx.def_var(var, string_index_val)
              when Bytecode::Insns::PopIndex
                var = variables[insn.index]
                var_val = bcx.use_var(var)
                bcx.def_var(string_index, var_val)
              when Bytecode::Insns::TestBegin
                string_index_val = bcx.use_var(string_index)
                v = bcx.icmp(:e, string_index_val, zero)
                flag_val = bcx.select(v, one, zero)
                bcx.def_var(flag, flag_val)
              when Bytecode::Insns::TestEnd
                string_index_val = bcx.use_var(string_index)
                v = bcx.icmp(:e, string_index_val, string_length)
                flag_val = bcx.select(v, one, zero)
                bcx.def_var(flag, flag_val)
              when Bytecode::Insns::TestAny
                string_index_val = bcx.use_var(string_index)
                v = bcx.icmp(:ne, string_index_val, string_length)
                flag_val = bcx.select(v, one, zero)
                increased = bcx.iadd(string_index_val, flag_val)
                bcx.def_var(string_index, increased)
                bcx.def_var(flag, flag_val)
              when Bytecode::Insns::TestValue
                end_block = bcx.create_block

                string_index_val = bcx.use_var(string_index)
                bcx.def_var(flag, zero)
                bcx.br_icmp(:e, string_index_val, string_length, end_block, [])

                jump_to_next_block(bcx)
                char_ptr = bcx.iadd(string_pointer, string_index_val)
                char = bcx.load(:I8, char_ptr, 0)
                expected_char = bcx.iconst(:I8, insn.char.ord)
                v = bcx.icmp(:e, char, expected_char)
                flag_val = bcx.select(v, one, zero)
                increased = bcx.iadd(string_index_val, flag_val)

                bcx.def_var(string_index, increased)
                bcx.def_var(flag, flag_val)
                bcx.jump(end_block, [])

                bcx.switch_to_block(end_block)
              when Bytecode::Insns::TestValuesInvert
                end_block = bcx.create_block
                after_checks_block = bcx.create_block

                string_index_val = bcx.use_var(string_index)
                bcx.def_var(flag, zero)
                bcx.br_icmp(:e, string_index_val, string_length, end_block, [])

                jump_to_next_block(bcx)
                char_ptr = bcx.iadd(string_pointer, string_index_val)
                char = bcx.load(:I8, char_ptr, 0)

                insn.chars.each do |value|
                  jump_to_next_block(bcx)
                  expected_char = bcx.iconst(:I8, value.ord)
                  v = bcx.icmp(:e, char, expected_char)
                  flag_val = bcx.select(v, zero, one)
                  bcx.def_var(flag, flag_val)
                  bcx.brz(flag_val, after_checks_block, [])
                end
                bcx.jump(after_checks_block, [])

                bcx.switch_to_block(after_checks_block)
                flag_val = bcx.use_var(flag)
                increased = bcx.iadd(string_index_val, flag_val)
                bcx.def_var(string_index, increased)
                bcx.def_var(flag, flag_val)
                bcx.jump(end_block, [])

                bcx.switch_to_block(end_block)
              when Bytecode::Insns::TestRange
                no_match_block = bcx.create_block
                post_length_check_block = bcx.create_block
                post_in_range_left_check_block = bcx.create_block
                post_in_range_right_check_block = bcx.create_block

                end_block = bcx.create_block
                string_index_val = bcx.use_var(string_index)
                bcx.br_icmp(:e, string_index_val, string_length, no_match_block, [])
                bcx.jump(post_length_check_block, [])

                bcx.switch_to_block(post_length_check_block)
                char_ptr = bcx.iadd(string_pointer, string_index_val)
                char = bcx.load(:I8, char_ptr, 0)
                left_range_char = bcx.iconst(:I8, insn.left.ord)
                right_range_char = bcx.iconst(:I8, insn.right.ord)
                bcx.br_icmp(:sl, char, left_range_char, no_match_block, [])
                bcx.jump(post_in_range_left_check_block, [])

                bcx.switch_to_block(post_in_range_left_check_block)
                bcx.br_icmp(:sg, char, right_range_char, no_match_block, [])
                bcx.jump(post_in_range_right_check_block, [])

                bcx.switch_to_block(post_in_range_right_check_block)
                increased = bcx.iadd(string_index_val, one)
                bcx.def_var(string_index, increased)
                bcx.def_var(flag, one)
                bcx.jump(end_block, [])

                bcx.switch_to_block(no_match_block)
                bcx.def_var(flag, zero)
                bcx.jump(end_block, [])

                bcx.switch_to_block(end_block)
              when Bytecode::Insns::TestType
                end_block = bcx.create_block

                string_index_val = bcx.use_var(string_index)
                bcx.def_var(flag, zero)
                bcx.br_icmp(:e, string_index_val, string_length, end_block, [])

                jump_to_next_block(bcx)
                char_ptr = bcx.iadd(string_pointer, string_index_val)
                char = bcx.load(:I8, char_ptr, 0)
                external_func_addr = bcx.iconst(:I64, insn.type.handle)
                res = bcx.call_indirect(external_func_sigref, external_func_addr, [char])
                values = bcx.inst_results(res)
                flag_val = bcx.select(values[0], one, zero)
                increased = bcx.iadd(string_index_val, flag_val)

                bcx.def_var(string_index, increased)
                bcx.def_var(flag, flag_val)
                bcx.jump(end_block, [])

                bcx.switch_to_block(end_block)
              when Bytecode::Insns::TestPositiveLookahead
                end_block = bcx.create_block

                string_index_val = bcx.use_var(string_index)
                bcx.def_var(flag, zero)
                bcx.br_icmp(:e, string_index_val, string_length, end_block, [])

                jump_to_next_block(bcx)
                char_ptr = bcx.iadd(string_pointer, string_index_val)

                insn.value.each_char.with_index do |c, index|
                  # Move the correct character into the buffer
                  jump_to_next_block(bcx)
                  lookahead = bcx.iconst(:I64, index)
                  char_ptr_ahead = bcx.iadd(char_ptr, lookahead)
                  char = bcx.load(:I8, char_ptr_ahead, 0)
                  expected_char = bcx.iconst(:I8, c.ord)
                  v = bcx.icmp(:e, char, expected_char)
                  flag_val = bcx.select(v, one, zero)
                  bcx.def_var(flag, flag_val)
                  bcx.brz(flag_val, end_block, [])
                end
                bcx.jump(end_block, [])
                bcx.switch_to_block(end_block)
              when Bytecode::Insns::TestNegativeLookahead
                end_block = bcx.create_block

                string_index_val = bcx.use_var(string_index)
                bcx.def_var(flag, one)
                bcx.br_icmp(:e, string_index_val, string_length, end_block, [])

                jump_to_next_block(bcx)
                char_ptr = bcx.iadd(string_pointer, string_index_val)

                insn.value.each_char.with_index do |c, index|
                  # Move the correct character into the buffer
                  jump_to_next_block(bcx)
                  lookahead = bcx.iconst(:I64, index)
                  char_ptr_ahead = bcx.iadd(char_ptr, lookahead)
                  char = bcx.load(:I8, char_ptr_ahead, 0)
                  expected_char = bcx.iconst(:I8, c.ord)
                  v = bcx.icmp(:ne, char, expected_char)
                  flag_val = bcx.select(v, one, zero)
                  bcx.def_var(flag, flag_val)
                  bcx.brnz(flag_val, end_block, [])
                end
                bcx.jump(end_block, [])
                bcx.switch_to_block(end_block)
              when Bytecode::Insns::TestRangeInvert
                no_match_block = bcx.create_block
                post_length_check_block = bcx.create_block
                post_in_range_left_check_block = bcx.create_block
                match_block = bcx.create_block

                end_block = bcx.create_block
                string_index_val = bcx.use_var(string_index)
                bcx.br_icmp(:e, string_index_val, string_length, no_match_block, [])
                bcx.jump(post_length_check_block, [])

                bcx.switch_to_block(post_length_check_block)
                char_ptr = bcx.iadd(string_pointer, string_index_val)
                char = bcx.load(:I8, char_ptr, 0)
                left_range_char = bcx.iconst(:I8, insn.left.ord)
                bcx.br_icmp(:sl, char, left_range_char, match_block, [])
                bcx.jump(post_in_range_left_check_block, [])

                bcx.switch_to_block(post_in_range_left_check_block)
                right_range_char = bcx.iconst(:I8, insn.right.ord)
                bcx.br_icmp(:sle, char, right_range_char, no_match_block, [])
                bcx.jump(match_block, [])

                bcx.switch_to_block(match_block)
                increased = bcx.iadd(string_index_val, one)
                bcx.def_var(string_index, increased)
                bcx.def_var(flag, one)
                bcx.jump(end_block, [])

                bcx.switch_to_block(no_match_block)
                bcx.def_var(flag, zero)
                bcx.jump(end_block, [])

                bcx.switch_to_block(end_block)
              when Bytecode::Insns::Branch
                true_block = cfg.label_map[insn.true_target]
                false_block = cfg.label_map[insn.false_target]
                flag_val = bcx.use_var(flag)
                bcx.br_icmp(:e, flag_val, one, block_map[true_block.name], [])
                bcx.jump(block_map[false_block.name], [])
              when Bytecode::Insns::Jump
                target_block = cfg.label_map[insn.target]
                bcx.jump(block_map[target_block.name], [])
              when Bytecode::Insns::Match
                # If we reach this instruction, then we've successfully matched
                # against the input string, so we're going to return the integer
                # that represents the index at which this match began
                ret = bcx.iconst(:I8, MATCHING_SUCCESS)
                bcx.return([ret])
              when Bytecode::Insns::Fail
                match_index_val = bcx.use_var(match_index)
                increased = bcx.iadd(one, match_index_val)
                bcx.def_var(match_index, increased)
                bcx.jump(start_loop_head, [])
              when Bytecode::Insns::StartCapture
                capture_index = insn.index * 16
                string_index_val = bcx.use_var(string_index)
                bcx.store(string_index_val, captures_pointer, capture_index)
              when Bytecode::Insns::EndCapture
                capture_index = insn.index * 16 + 8
                string_index_val = bcx.use_var(string_index)
                bcx.store(string_index_val, captures_pointer, capture_index)
              else
                raise
              end
            end
          end
          bcx.switch_to_block(exit_block)
          res = bcx.iconst(:I8, MATCHING_FAILED)
          bcx.return([res])

          bcx.finalize
        })
        b.finalize
        f_ptr = b.get_function_pointer(f)
        f_size = b.get_function_size(f)
        Compiled.new(f_ptr, f_size, cfg.captures)
      end
    end
  end
end
