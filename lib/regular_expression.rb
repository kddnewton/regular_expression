# frozen_string_literal: true

require_relative "./regular_expression/ast"
require_relative "./regular_expression/lexer"
require_relative "./regular_expression/nfa"
require_relative "./regular_expression/optimize"
require_relative "./regular_expression/parser"
require_relative "./regular_expression/bytecode"
require_relative "./regular_expression/compiler"
require_relative "./regular_expression/interpreter"
require_relative "./regular_expression/cfg"
require_relative "./regular_expression/rubygen"
require_relative "./regular_expression/nativegen"

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
