# frozen_string_literal: true

module RegularExpression
  # An interpreter for our compiled bytecode. Maybe we could make this possible
  # to enter at a given state and deoptimise to it from the compiled code?
  class Interpreter
    def match?(bytecode, string)
      (0..string.size).any? do |start_n|
        string_n = start_n
        insn_n = 0

        while true
          insn = bytecode.insns[insn_n]

          case insn
          when Bytecode::Insns::GuardBegin
            return false if start_n != 0

            insn_n = bytecode.labels[insn.then]
          when Bytecode::Insns::GuardEnd
            break if string_n != string.size

            insn_n = bytecode.labels[insn.then]
          when Bytecode::Insns::JumpAny
            if string_n < string.size
              string_n += 1
              insn_n = bytecode.labels[insn.target]
            else
              insn_n += 1
            end
          when Bytecode::Insns::JumpValue
            if string_n < string.size && string[string_n] == insn.char
              string_n += 1
              insn_n = bytecode.labels[insn.target]
            else
              insn_n += 1
            end
          when Bytecode::Insns::JumpInvert
            if string_n < string.size && !insn.values.include?(string[string_n])
              string_n += 1
              insn_n = bytecode.labels[insn.target]
            else
              insn_n += 1
            end
          when Bytecode::Insns::JumpRange
            if string_n < string.size && string[string_n] >= insn.left && string[string_n] <= insn.right
              string_n += 1
              insn_n = bytecode.labels[insn.target]
            else
              insn_n += 1
            end
          when Bytecode::Insns::Jump
            insn_n = bytecode.labels[insn.target]
          when Bytecode::Insns::Match
            return true
          when Bytecode::Insns::Fail
            break
          else
            raise
          end
        end
      end
    end
  end
end
