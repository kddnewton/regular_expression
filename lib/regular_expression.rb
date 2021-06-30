# frozen_string_literal: true

require_relative "./regular_expression/ast"
require_relative "./regular_expression/lexer"
require_relative "./regular_expression/nfa"
require_relative "./regular_expression/parser"

module RegularExpression
  class Pattern
    # NFA::StartState
    attr_reader :nfa

    def initialize(nfa)
      @nfa = nfa
    end

    def match?(string)
      string.length.times.any? { |index| nfa.accept(string, index) }
    end
  end

  def self.pattern(source)
    parser = RegularExpression::Parser.new
    Pattern.new(parser.parse(source).to_nfa)
  end
end
