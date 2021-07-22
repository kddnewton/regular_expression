# frozen_string_literal: true

module RegularExpression
  # An interpreter for our compiled bytecode. Maybe we could make this possible
  # to enter at a given state and deoptimise to it from the compiled code?
  class Interpreter
    ProfileEntry = Struct.new(:total_hits, :true_hits)

    attr_reader :bytecode

    def initialize(bytecode)
      @bytecode = bytecode
    end

    # This is just here for API parity with the compiled outputs.
    def to_proc
      interpreter = self
      ->(string) { interpreter.match(string) }
    end

    def match(string)
      interpret(string, nil)
    end

    def self.empty_profiling_data
      Hash.new { |h, k| h[k] = ProfileEntry.new(0, 0) }
    end

    def interpret(string, profiling_data)
      stack = []
      captures = [-1] * bytecode.captures.length * 2

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
          when Bytecode::Insns::StartCapture
            captures[insn.index * 2] = string_n
            insn_n += 1
          when Bytecode::Insns::EndCapture
            captures[insn.index * 2 + 1] = string_n
            insn_n += 1
          when Bytecode::Insns::TestAny
            flag = string_n < string.size
            string_n += 1 if flag
            insn_n += 1
          when Bytecode::Insns::TestValue
            flag = string_n < string.size && IgnoreCase.matches?(string[string_n], insn.ignore_case) do |char|
              char == insn.char
            end
            string_n += 1 if flag
            insn_n += 1
          when Bytecode::Insns::TestType
            flag = string_n < string.size && insn.type.match?(string[string_n])
            #flag = string_n < string.size && IgnoreCase.matches?(string[string_n], insn.ignore_case) do |char|
              #insn.type.match?(char)
            #end
            string_n += 1 if flag
            insn_n += 1
          when Bytecode::Insns::TestValuesInvert
            flag = string_n < string.size && IgnoreCase.matches?(string[string_n], insn.ignore_case) do |char|
              !insn.chars.include?(string[string_n])
            end
            string_n += 1 if flag
            insn_n += 1
          when Bytecode::Insns::TestRange
            flag = string_n < string.size && IgnoreCase.matches?(string[string_n], insn.ignore_case) do |char|
              char >= insn.left && char <= insn.right
            end
            string_n += 1 if flag
            insn_n += 1
          when Bytecode::Insns::TestRangeInvert
            flag = string_n < string.size && IgnoreCase.matches?(string[string_n], insn.ignore_case) do |char|
              char >= insn.left && char <= insn.right
            end

            string_n += 1 if flag
            insn_n += 1
          when Bytecode::Insns::TestPositiveLookahead
            flag = if insn.ignore_case
                string[string_n..].downcase.start_with?(insn.value.downcase)
              else
                string[string_n..].start_with?(insn.value)
              end
            insn_n += 1
          when Bytecode::Insns::TestNegativeLookahead
            flag = if insn.ignore_case
                !string[string_n..].downcase.start_with?(insn.value.downcase)
              else
                !string[string_n..].start_with?(insn.value)
              end
            insn_n += 1
          when Bytecode::Insns::Branch
            if profiling_data
              entry = profiling_data[insn]
              entry.total_hits += 1
              entry.true_hits += 1 if flag
            end

            insn_n =
              if flag
                bytecode.labels[insn.true_target]
              else
                bytecode.labels[insn.false_target]
              end
          when Bytecode::Insns::Jump
            insn_n = bytecode.labels[insn.target]
          when Bytecode::Insns::Match
            return captures
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
