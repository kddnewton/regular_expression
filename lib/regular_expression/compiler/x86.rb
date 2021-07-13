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
          -> (string) { function.call(string, string.size) == 1 }
        end
      end

      # Generate native code for a CFG. This looks just like the Ruby generator
      # but abstracted one level, or just like the interpreter but abstracted
      # two levels!
      #
      # Here we're compiling down to X86. Here's the breakdown of how we're
      # using the registers:
      #
      # *             rax - the return value
      # *             rcx - the index where we're currently progressed
      # *             rdx - the index where we're starting the machine to match
      # * (preserved) rbx
      # * (preserved) rsp - the stack pointer
      # * (preserved) rbp - the stack base pointer
      # *             rsi - the second argument (the string length)
      # *             rdi - the first argument (a pointer to the string)
      # *             r8  - the last character that was read from the string
      # *             r9
      # *             r10
      # *             r11
      # * (preserved) r12
      # * (preserved) r13
      # * (preserved) r14
      # * (preserved) r15
      def self.compile(cfg)
        fisk = Fisk.new
        buffer = Fisk::Helpers.jitbuffer(1024)

        fisk.asm(buffer) do
          push rbp
          mov rbp, rsp
          mov rdx, imm64(0)

          make_label :start_loop_head
          cmp rdx, rsi
          jg label(:search_loop_exit)

          mov rcx, rdx

          cfg.blocks.each do |block|
            make_label block.name

            block.insns.each do |insn|
              case insn
              when Bytecode::Insns::PushIndex
                push rcx
              when Bytecode::Insns::PopIndex
                pop rcx
              when Bytecode::Insns::GuardBegin
                cmp rcx, imm8(0)
                jne label(:search_loop_exit)
                jmp label(cfg.exit_map[insn.then].name)
              when Bytecode::Insns::GuardEnd
                cmp rcx, rsi
                je label(cfg.exit_map[insn.then].name)
              when Bytecode::Insns::JumpAny
                no_match_label = :"no_match_#{insn.object_id}"

                cmp rcx, rsi
                je label(no_match_label)

                inc rcx
                jmp label(cfg.exit_map[insn.target].name)

                make_label no_match_label
              when Bytecode::Insns::JumpValue
                no_match_label = :"no_match_#{insn.object_id}"

                cmp rcx, rsi
                je label(no_match_label)

                mov r8, rdi
                add r8, rcx
                mov r8, m64(r8)
                cmp r8, imm8(insn.char.ord)
                jne label(no_match_label)

                inc rcx
                jmp label(cfg.exit_map[insn.target].name)

                make_label no_match_label
              when Bytecode::Insns::JumpValuesInvert
                no_match_label = :"no_match_#{insn.object_id}"

                cmp rcx, rsi
                je label(no_match_label)

                mov r8, rdi
                add r8, rcx
                mov r8, m64(r8)

                insn.values.each do |value|
                  cmp r8, imm8(value.ord)
                  je label(no_match_label)
                end

                inc rcx
                jmp label(cfg.exit_map[insn.target].name)

                make_label no_match_label
              when Bytecode::Insns::JumpRange
                no_match_label = :"no_match_#{insn.object_id}"

                cmp rcx, rsi
                je label(no_match_label)

                mov r8, rdi
                add r8, rcx
                mov r8, m64(r8)

                cmp r8, imm8(insn.left.ord)
                jl label(no_match_label)

                cmp r8, imm8(insn.right.ord)
                jg label(no_match_label)

                inc rcx
                jmp label(cfg.exit_map[insn.target].name)

                make_label no_match_label
              when Bytecode::Insns::JumpRangeInvert
                no_match_label = :"no_match_#{insn.object_id}"
                match_label = :"match_#{insn.object_id}"

                cmp rcx, rsi
                je label(no_match_label)

                mov r8, rdi
                add r8, rcx
                mov r8, m64(r8)

                cmp r8, imm8(insn.left.ord)
                jl label(match_label)

                cmp r8, imm8(insn.right.ord)
                jle label(no_match_label)

                make_label match_label
                inc rcx
                jmp label(cfg.exit_map[insn.target].name)

                make_label no_match_label
              when Bytecode::Insns::Jump
                jmp label(cfg.exit_map[insn.target].name)
              when Bytecode::Insns::Match
                mov rax, imm64(1)
                mov rsp, rbp
                pop rbp
                ret
              when Bytecode::Insns::Fail
                inc rdx
                jmp label(:start_loop_head)
              else
                raise
              end
            end
          end

          make_label :search_loop_exit
          mov rax, imm64(0)
          mov rsp, rbp
          pop rbp
          ret
        end

        Compiled.new(buffer)
      end
    end
  end
end
