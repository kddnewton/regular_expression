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

    def test_group
      parse("(a|b)") => AST::Pattern[AST::Expression[
        AST::Group[
          AST::Expression[
            AST::MatchCharacter[value: "a"]
          ],
          AST::Expression[
            AST::MatchCharacter[value: "b"]
          ]
        ]
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

    def test_range_quantifier
      parse("a{3}") => AST::Pattern[AST::Expression[
        AST::Quantified[
          AST::MatchCharacter[value: "a"],
          AST::RangeQuantifier[minimum: 3, maximum: 3]
        ]
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
      Parser.new(source).parse.tap { |node| PP.pp(node, +"") }
    end
  end
end
