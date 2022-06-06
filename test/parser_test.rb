# frozen_string_literal: true

require "test_helper"
require "pp"

module RegularExpression
  class ParserTest < Minitest::Test
    def test_alternation
      parse("a|b|c") => AST::Pattern[
        AST::Expression[AST::MatchCharacter[value: "a"]],
        AST::Expression[AST::MatchCharacter[value: "b"]],
        AST::Expression[AST::MatchCharacter[value: "c"]]
      ]
    end

    def test_concatenation
      parse("abc") => AST::Pattern[AST::Expression[
        AST::MatchCharacter[value: "a"],
        AST::MatchCharacter[value: "b"],
        AST::MatchCharacter[value: "c"]
      ]]
    end

    def test_match_character
      parse("a") => AST::Pattern[AST::Expression[
        AST::MatchCharacter[value: "a"]
      ]]
    end

    def test_match_any
      parse(".") => AST::Pattern[AST::Expression[
        AST::MatchAny
      ]]
    end

    def test_star_quantifier
      parse("a*") => AST::Pattern[AST::Expression[
        AST::Quantified[
          AST::MatchCharacter[value: "a"],
          AST::StarQuantifier
        ]
      ]]
    end

    private

    def parse(source)
      Parser.new(source).parse.tap do |node|
        PP.pp(node, +"")

        nfa = NFA.compile(node)
        NFA.match?(nfa, "a")

        dfa = DFA.compile(nfa)
        DFA.match?(dfa, "a")
      end
    end
  end
end
