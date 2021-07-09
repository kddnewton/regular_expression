# frozen_string_literal: true

module RegularExpression
  class Pattern
    attr_reader :bytecode

    def initialize(source)
      parser = RegularExpression::Parser.new
      nfa = parser.parse(source).to_nfa

      @bytecode = RegularExpression::Bytecode.compile(nfa)
    end

    def match?(string)
      interpreter = RegularExpression::Interpreter.new
      interpreter.match?(bytecode, string)
    end
  end
end
