# frozen_string_literal: true

module RegularExpression
  class Pattern
    # NFA::StartState
    attr_reader :nfa

    def initialize(source)
      parser = RegularExpression::Parser.new
      @nfa = parser.parse(source).to_nfa
    end

    def match?(string)
      (string.length + 1).times.any? { |index| nfa.accept(string, index) }
    end
  end
end
