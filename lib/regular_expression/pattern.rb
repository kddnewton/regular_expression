# frozen_string_literal: true

module RegularExpression
  class Pattern
    attr_reader :nfa

    def initialize(source)
      parser = RegularExpression::Parser.new
      @nfa = parser.parse(source).to_nfa

      # compiler = RegularExpression::Compiler.new
      # @compiled = compiler.compile(nfa)
    end

    def match?(string)
      # interpreter = RegularExpression::Interpreter.new
      # interpreter.match?(@compiled, string)

      (string.length + 1).times.any? { |index| nfa.accept(string, index) }
    end
  end
end
