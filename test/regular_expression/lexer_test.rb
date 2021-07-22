# frozen_string_literal: true

require "test_helper"

module RegularExpression
  class LexerTest < Minitest::Test
    def test_char_lists
      assert_tokens("ab", [[:CHAR, "a"], [:CHAR, "b"]])
    end

    def test_known_character_class
      assert_tokens("\\w", [[:CHAR_CLASS, "\\w"]])
      assert_tokens("\\W", [[:CHAR_CLASS, "\\W"]])
      assert_tokens("\\d", [[:CHAR_CLASS, "\\d"]])
      assert_tokens("\\D", [[:CHAR_CLASS, "\\D"]])
      assert_tokens("\\h", [[:CHAR_CLASS, "\\h"]])
      assert_tokens("\\H", [[:CHAR_CLASS, "\\H"]])
      assert_tokens("\\s", [[:CHAR_CLASS, "\\s"]])
      assert_tokens("\\S", [[:CHAR_CLASS, "\\S"]])
    end

    def test_anchors
      assert_tokens("\\z", [[:ANCHOR, "\\z"]])
      assert_tokens("\\A", [[:ANCHOR, "\\A"]])
      assert_tokens("$", [[:ANCHOR, "$"]])
    end

    def test_digit
      assert_tokens("0", [[:DIGIT, "0"]])
    end

    def test_symbols
      assert_tokens("^", [[:CARET, "^"]])
      assert_tokens("(", [[:LPAREN, "("]])
      assert_tokens(")", [[:RPAREN, ")"]])
      assert_tokens("[", [[:LBRACKET, "["]])
      assert_tokens("]", [[:RBRACKET, "]"]])
      assert_tokens("{", [[:LBRACE, "{"]])
      assert_tokens("}", [[:RBRACE, "}"]])
      assert_tokens("|", [[:PIPE, "|"]])
      assert_tokens("*", [[:STAR, "*"]])
      assert_tokens("+", [[:PLUS, "+"]])
      assert_tokens("?", [[:QMARK, "?"]])
      assert_tokens(".", [[:PERIOD, "."]])
      assert_tokens("-", [[:DASH, "-"]])
      assert_tokens(",", [[:COMMA, ","]])
    end

    def test_escape_backslashes
      assert_tokens("\\\\s", [[:CHAR, "\\"], [:CHAR, "s"]])
      assert_tokens("\\\\z", [[:CHAR, "\\"], [:CHAR, "z"]])
    end

    def test_escape_special_characters
      assert_tokens("1\\+", [[:DIGIT, "1"], [:CHAR, "+"]])
    end

    def test_extended_mode
      tokens = Lexer.new(<<~REGEXP, Flags.new(Regexp::EXTENDED)).tokens
        \\A
        [[:digit:]]+ # 1 or more digits before the decimal point
        (\\.         # Decimal point
        [[:digit:]]+ # 1 or more digits after the decimal point
        )?           # The decimal point and following digits are optional
        \\z
      REGEXP

      expected = %i[
        ANCHOR
        CHAR_TYPE PLUS
        LPAREN CHAR
        CHAR_TYPE PLUS
        RPAREN QMARK
        ANCHOR
      ]

      assert_equal(expected, tokens.tap(&:pop).map(&:first))
    end

    def test_non_extended_mode_comments
      assert_tokens("(?#comment)a", [[:CHAR, "a"]])
    end

    private

    def assert_tokens(string, expected, flags = Flags.new)
      actual = Lexer.new(string, flags).tokens
      assert_equal([false, "end"], actual.last, "Tokens must end with #{[false, 'end'].inspect}")

      actual.pop
      assert_equal(expected, actual)
    end
  end
end
