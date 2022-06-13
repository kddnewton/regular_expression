# frozen_string_literal: true

require "fileutils"
require "set"
require "stringio"

require_relative "regular_expression/alphabet"
require_relative "regular_expression/ast"
require_relative "regular_expression/dfa"
require_relative "regular_expression/digraph"
require_relative "regular_expression/flags"
require_relative "regular_expression/nfa"
require_relative "regular_expression/parser"

module RegularExpression
  # This is the main class that represents a regular expression. It effectively
  # mirrors Regexp from core Ruby.
  class Pattern
    attr_reader :source, :flags, :machine

    def initialize(source, flags = "")
      @source = source
      @flags = Flags[flags]

      # We inject .* into the source so that when we loop over the input strings
      # to check for matches we don't have to look at every index in the string.
      normalized = ".*#{source}"

      # Compile the source into an AST, then an NFA, then a DFA.
      @machine = DFA.compile(NFA.compile(Parser.new(normalized, flags).parse))
    end

    def match?(string)
      DFA.match?(machine, string)
    end
  end
end
