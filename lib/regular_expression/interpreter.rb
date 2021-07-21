# frozen_string_literal: true

module RegularExpression
  # An interpreter for our compiled bytecode. Maybe we could make this possible
  # to enter at a given state and deoptimise to it from the compiled code?
  class Interpreter
    attr_reader :bytecode

    def initialize(bytecode)
      @bytecode = bytecode
    end

    # This is just here for API parity with the compiled outputs.
    def to_proc
      interpreter = self
      ->(string) { interpreter.match?(string) }
    end

    def match?(string)
      stack = []

      (0..string.size).each do |start_n|
        string_n = start_n
        insn_n = 0
        flag = false

        loop do
          insn = bytecode.insns[insn_n]

          case insn
          when Bytecode::Insns::PushIndex
            stack << string_n
            insn_n += 1
          when Bytecode::Insns::PopIndex
            string_n = stack.pop
            insn_n += 1
          when Bytecode::Insns::TestBegin
            flag = start_n.zero?
            insn_n += 1
          when Bytecode::Insns::TestEnd
            flag = string_n == string.size
            insn_n += 1
          when Bytecode::Insns::TestAny
            flag = string_n < string.size
            string_n += 1 if flag
            insn_n += 1
          when Bytecode::Insns::TestValue
            flag = string_n < string.size && string[string_n] == insn.char
            string_n += 1 if flag
            insn_n += 1
          when Bytecode::Insns::TestType
            flag = string_n < string.size && insn.type.match?(string[string_n])
            string_n += 1 if flag
            insn_n += 1
          when Bytecode::Insns::TestValuesInvert
            flag = string_n < string.size && !insn.chars.include?(string[string_n])
            string_n += 1 if flag
            insn_n += 1
          when Bytecode::Insns::TestRange
            flag = string_n < string.size && string[string_n] >= insn.left && string[string_n] <= insn.right
            string_n += 1 if flag
            insn_n += 1
          when Bytecode::Insns::TestRangeInvert
            flag = string_n < string.size && (string[string_n] < insn.left || string[string_n] > insn.right)
            string_n += 1 if flag
            insn_n += 1
          when Bytecode::Insns::Branch
            insn_n = if flag
                       bytecode.labels[insn.true_target]
                     else
                       bytecode.labels[insn.false_target]
                     end
          when Bytecode::Insns::Jump
            insn_n = bytecode.labels[insn.target]
          when Bytecode::Insns::Match
            return start_n
          when Bytecode::Insns::Fail
            break
          else
            raise
          end
        end
      end

      nil
    end
  end
end
