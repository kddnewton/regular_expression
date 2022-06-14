# frozen_string_literal: true

require "set"

require_relative "regular_expression/alphabet"
require_relative "regular_expression/ast"
require_relative "regular_expression/dfa"
require_relative "regular_expression/digraph"
require_relative "regular_expression/flags"
require_relative "regular_expression/nfa"
require_relative "regular_expression/parser"
require_relative "regular_expression/unicode"
require_relative "regular_expression/utf8"

module RegularExpression
  # This is the main class that represents a regular expression. It effectively
  # mirrors Regexp from core Ruby.
  class Pattern
    attr_reader :source, :flags, :machine

    def initialize(source, flags = "")
      @source = source
      @flags = Flags[flags]
      @machine = dfa
    end

    def ast
      # We inject .* into the source so that when we loop over the input strings
      # to check for matches we don't have to look at every index in the string.
      Parser.new(".*#{source}", flags).parse
    end

    def nfa
      NFA.compile(ast)
    end

    def dfa
      DFA.compile(nfa)
    end

    def match?(string)
      machine.match?(string)
    end
  end
end
