# frozen_string_literal: true

module RegularExpression
  # An interpreter for our compiled bytecode. Maybe we could make this possible
  # to enter at a given state and deoptimise to it from the compiled code?
  class Interpreter
    def match?(compiled, string)
      start_n = 0

      while start_n < string.size
        string_n = start_n
        insn_n = 0

        while true
          insn = compiled.insns[insn_n]

          case insn
          when Bytecode::Insns::Start
            insn_n += 1
          when Bytecode::Insns::Read
            if string[string_n] == insn.char
              string_n += 1
              insn_n = compiled.labels[insn.then]
            else
              insn_n += 1
            end
          when Bytecode::Insns::Jump
            insn_n = compiled.labels[insn.target]
          when Bytecode::Insns::Finish
            return true
          when Bytecode::Insns::Fail
            break
          else
            raise
          end
        end

        start_n += 1
      end
      false
    end
  end
end
