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
      def self.compile(cfg)
        fisk = Fisk.new
        buffer = Fisk::Helpers.jitbuffer(1024)

        fisk.asm(buffer) do
          # rdi (string) = arg[0]
          # rsi (string.size) = arg[1]
          push rbp
          mov rbp, rsp

          # rdx (start_n) = 0
          mov rdx, imm64(0)

          # while rdx (start_n) < rsi (string.size)
          make_label :start_loop_head
          cmp rdx, rsi
          jg label(:search_loop_exit)

          # rcx (string_n) = (rdx) start_n
          mov rcx, rdx

          cfg.blocks.each do |block|
            make_label block.name

            block.insns.each do |insn|
              case insn
              when Bytecode::Insns::BeginAnchor
                cmp rcx, imm8(0)
                jne label(:search_loop_exit)
                jmp label(cfg.exit_map[insn.then].name)
              when Bytecode::Insns::EndAnchor
                cmp rcx, rsi
                je label(cfg.exit_map[insn.then].name)
              when Bytecode::Insns::Any
                cmp rcx, rsi
                no_match_label = :"no_match_#{insn.object_id}"
                je label(no_match_label)

                # rcx (string_n) += 1
                inc rcx

                # goto next block
                jmp label(cfg.exit_map[insn.then].name)

                make_label no_match_label
              when Bytecode::Insns::Value
                # if string (rdi)[string_n (rcx)] == char
                mov r8, rdi
                add r8, rcx
                mov r8, m64(r8)
                cmp r8, imm8(insn.char.ord) # I want to do rdi[rcx] but can't figure out how in Fisk
                no_match_label = :"no_match_#{insn.object_id}"
                jne label(no_match_label)

                # rcx (string_n) += 1
                inc rcx

                # goto next block
                jmp label(cfg.exit_map[insn.then].name)

                make_label no_match_label
              when Bytecode::Insns::Set
                raise
              when Bytecode::Insns::Range
                no_match_label = :"no_match_#{insn.object_id}"

                mov r8, rdi
                add r8, rcx
                mov r8, m64(r8)

                # if string (rdi)[string_n (rcx)] < insn.left
                cmp r8, imm8(insn.left.ord)
                jl label(no_match_label)

                # if string (rdi)[string_n (rcx)] > insn.right
                cmp r8, imm8(insn.right.ord)
                jg label(no_match_label)

                # rcx (string_n) += 1
                inc rcx

                # goto next block
                jmp label(cfg.exit_map[insn.then].name)

                make_label no_match_label
              when Bytecode::Insns::Jump
                jmp label(cfg.exit_map[insn.target].name)
              when Bytecode::Insns::Match
                # return 1
                mov rax, imm64(1)
                pop rbp
                ret
              when Bytecode::Insns::Fail
                # rdx (start_n) += 1
                inc rdx

                jmp label(:start_loop_head)
              else
                raise
              end
            end
          end

          # exit_search_loop:
          make_label :search_loop_exit

          mov rax, imm64(0)
          pop rbp
          ret
        end

        Compiled.new(buffer)
      end
    end
  end
end
