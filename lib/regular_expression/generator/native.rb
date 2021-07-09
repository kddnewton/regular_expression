# frozen_string_literal: true

module RegularExpression
  module Generator
    module Native
      # Generate native code for a CFG. This looks just like the Ruby generator
      # but abstracted one level, or just like the interpreter but abstracted
      # two levels!
      def self.generate(cfg)
        fisk = Fisk.new
        jitbuf = Fisk::Helpers.jitbuffer(1024)

        fisk.asm(jitbuf) do
          # rdi (string) = arg[0]
          # rsi (string.size) = arg[1]
          push rbp
          mov rbp, rsp

          # rdx (start_n) = 0
          mov rdx, imm64(0)

          # while rdx (start_n) < rsi (string.size)
          make_label :start_loop_head
          cmp rdx, rsi
          jge label(:search_loop_exit)

          # rcx (string_n) = (rdx) start_n
          mov rcx, rdx

          cfg.blocks.each do |block|
            make_label block.name

            block.insns.each do |insn|
              case insn
              when Bytecode::Insns::Start
                next
              when Bytecode::Insns::Any
                cmp rcx, rsi
                no_match_label = :"no_match_#{insn.object_id}"
                je label(no_match_label)

                # rcx (string_n) += 1
                inc rcx

                # goto next block
                jmp label(cfg.exit_map[insn.then].name)

                make_label no_match_label
              when Bytecode::Insns::Read
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
              when Bytecode::Insns::Jump
                jmp label(cfg.exit_map[insn.target].name)
              when Bytecode::Insns::Finish
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
      end
    end
  end
end
