# frozen_string_literal: true

module RegularExpression
  module Compiler
    module X86
      class Compiled
        attr_reader :buffer

        def initialize(buffer)
          @buffer = buffer
        end

        def disasm
          output = StringIO.new

          crabstone = Crabstone::Disassembler.new(Crabstone::ARCH_X86, Crabstone::MODE_64)
          crabstone.disasm(buffer.memory.to_s(buffer.pos), buffer.memory.to_i).each do |insn|
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
          function = buffer.to_function([Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T], Fiddle::TYPE_SIZE_T)

          lambda do |string|
            value = function.call(string, string.length)
            value if value != string.length + 1
          end
        end
      end

      # Generate native code for a CFG. This looks just like the Ruby generator
      # but abstracted one level, or just like the interpreter but abstracted
      # two levels!
      def self.compile(cfg)
        fisk = Fisk.new
        buffer = Fisk::Helpers.jitbuffer(1024)

        fisk.asm(buffer) do
          # Here we're setting up a couple of local variables that point to
          # registers so that it's easier to see what's actually going on

          # rax is a scratch register that is used for the return value of the
          # function
          return_value = rax

          # rcx is a scratch register that is used to track the index of the
          # string where we're currently looking
          string_index = rcx

          # rdx is a scratch register that is used to track the index of the
          # string where we've started the match
          match_index = rdx

          # rsp is a reserved register that stores a pointer to the stack
          stack_pointer = rsp

          # rbp is a reserved register that stores a pointer to the base of the
          # stack. It is also known as the frame pointer
          frame_pointer = rbp

          # rsi is a scratch register that stores the second argument to the
          # function, and in our case stores the length of the string
          string_length = rsi

          # rdi is a scratch register that stores the first argument to the
          # function, and in our case stores a pointer to the base of the string
          string_pointer = rdi

          # r8 is a scratch register that we're using to store the last read
          # character value from the string
          character_buffer = r8

          # First we're going to do some initialization of the frame pointer and
          # stack pointer so we can clear the stack when we're done with this
          # function
          push frame_pointer
          mov frame_pointer, stack_pointer

          # Now we're going to initialize the counter to 0 so that we attempt to
          # match at each index of the input string
          xor match_index, match_index

          # This is the start of our loop, where at the beginning of the loop
          # we check if we have already finished looking at each index (in which
          # case we'll jump to a failure condition)
          make_label :start_loop_head
          cmp match_index, string_length
          jg label(:exit)

          # Set the string_index value to the match_index value so that we begin
          # each loop at the current match index
          mov string_index, match_index

          cfg.blocks.each do |block|
            # Label the start of each block so that we can jump between them
            make_label block.name

            block.insns.each do |insn|
              case insn
              when Bytecode::Insns::PushIndex
                push string_index
              when Bytecode::Insns::PopIndex
                pop string_index
              when Bytecode::Insns::GuardBegin
                cmp string_index, imm8(0)
                jne label(:exit)
                jmp label(cfg.exit_map[insn.guarded].name)
              when Bytecode::Insns::GuardEnd
                cmp string_index, string_length
                je label(cfg.exit_map[insn.guarded].name)
              when Bytecode::Insns::JumpAny
                no_match_label = :"no_match_#{insn.object_id}"

                # Ensure we have a character we can read
                cmp string_index, string_length
                je label(no_match_label)

                # Move the string index forward and jump to the target
                # instruction
                inc string_index
                jmp label(cfg.exit_map[insn.target].name)

                make_label no_match_label
              when Bytecode::Insns::JumpValue
                no_match_label = :"no_match_#{insn.object_id}"

                # Ensure we have a character we can read
                cmp string_index, string_length
                je label(no_match_label)

                # Read the character into the character buffer
                mov character_buffer, string_pointer
                add character_buffer, string_index
                mov character_buffer, m64(character_buffer)

                # Compare the character buffer to the instruction's character,
                # continue on to the next instruction if it's not equal
                cmp character_buffer, imm8(insn.char.ord)
                jne label(no_match_label)

                # Move the string index forward and jump to the target
                # instruction
                inc string_index
                jmp label(cfg.exit_map[insn.target].name)

                make_label no_match_label
              when Bytecode::Insns::JumpValuesInvert
                no_match_label = :"no_match_#{insn.object_id}"

                # Ensure we have a character we can read
                cmp string_index, string_length
                je label(no_match_label)

                # Read the character into the character buffer
                mov character_buffer, string_pointer
                add character_buffer, string_index
                mov character_buffer, m64(character_buffer)

                # Compare the character buffer to each of the instruction's
                # characters, continue on to the next instruction if any of them
                # are equal
                insn.chars.each do |value|
                  cmp character_buffer, imm8(value.ord)
                  je label(no_match_label)
                end

                # Move the string index forward and jump to the target
                # instruction
                inc string_index
                jmp label(cfg.exit_map[insn.target].name)

                make_label no_match_label
              when Bytecode::Insns::JumpRange
                no_match_label = :"no_match_#{insn.object_id}"

                # Ensure we have a character we can read
                cmp string_index, string_length
                je label(no_match_label)

                # Read the character into the character buffer
                mov character_buffer, string_pointer
                add character_buffer, string_index
                mov character_buffer, m64(character_buffer)

                # Compare the character buffer to the left hand side of the
                # instruction's range, continue on to the next instruction if
                # it's outside the range
                cmp character_buffer, imm8(insn.left.ord)
                jl label(no_match_label)

                # Compare the character buffer to the right hand side of the
                # instruction's range, continue on to the next instruction if
                # it's outside the range
                cmp character_buffer, imm8(insn.right.ord)
                jg label(no_match_label)

                # Move the string index forward and jump to the target
                # instruction
                inc string_index
                jmp label(cfg.exit_map[insn.target].name)

                make_label no_match_label
              when Bytecode::Insns::JumpRangeInvert
                no_match_label = :"no_match_#{insn.object_id}"
                match_label = :"match_#{insn.object_id}"

                # Ensure we have a character we can read
                cmp string_index, string_length
                je label(no_match_label)

                # Read the character into the character buffer
                mov character_buffer, string_pointer
                add character_buffer, string_index
                mov character_buffer, m64(character_buffer)

                # Compare the character buffer to the left hand side of the
                # instruction's range, jump down to the success case if it's
                # outside the range
                cmp character_buffer, imm8(insn.left.ord)
                jl label(match_label)

                # Compare the character buffer to the right hand side of the
                # instruction's range, continue on to the next instruction if
                # it's inside the range
                cmp character_buffer, imm8(insn.right.ord)
                jle label(no_match_label)

                # Move the string index forward and jump to the target
                # instruction
                make_label match_label
                inc string_index
                jmp label(cfg.exit_map[insn.target].name)

                make_label no_match_label
              when Bytecode::Insns::Jump
                jmp label(cfg.exit_map[insn.target].name)
              when Bytecode::Insns::Match
                # If we reach this instruction, then we've successfully matched
                # against the input string, so we're going to return the integer
                # that represents the index at which this match began
                mov return_value, match_index
                mov stack_pointer, frame_pointer
                pop frame_pointer
                ret
              when Bytecode::Insns::Fail
                inc match_index
                jmp label(:start_loop_head)
              else
                raise
              end
            end
          end

          # If we reach this instruction, then we've failed to match at every
          # possible index in the string, so we're going to return the length
          # of the string + 1 so that the caller knows that this match failed
          make_label :exit
          mov return_value, string_length
          inc return_value

          # Here we make sure to clean up after ourselves by returning the frame
          # pointer to its former position
          mov stack_pointer, frame_pointer
          pop frame_pointer

          ret
        end

        Compiled.new(buffer)
      end
    end
  end
end
