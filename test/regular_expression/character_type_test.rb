# frozen_string_literal: true

require "test_helper"

module RegularExpression
  class CharacterTypeTest < Minitest::Test
    def test_alnum
      assert_character_type("alnum", %w[a 0], %w[!])
    end

    def test_alpha
      assert_character_type("alpha", %w[a z], %w[0])
    end

    def test_ascii
      assert_character_type("ascii", %w[a 0], %w[§])
    end

    def test_blank
      assert_character_type("blank", [" ", "\t"], %w[a])
    end

    def test_cntrl
      assert_character_type("cntrl", ["\u0000"], %w[a])
    end

    def test_digit
      assert_character_type("digit", %w[0 9], %w[a])
    end

    def test_graph
      assert_character_type("graph", %w[a 0], ["\u0000", " "])
    end

    def test_lower
      assert_character_type("lower", %w[a z], %w[A])
    end

    def test_print
      assert_character_type("print", ["a", "0", " "], ["\u0000"])
    end

    def test_punct
      assert_character_type("punct", %w[. !], %w[a 0])
    end

    def test_space
      assert_character_type("space", [" ", "\t"], %w[a 0])
    end

    def test_upper
      assert_character_type("upper", %w[A Z], %w[a])
    end

    def test_xdigit
      assert_character_type("xdigit", %w[a A 0], %w[i])
    end

    private

    def assert_character_type(type, matches, non_matches)
      character_type = CharacterType.new(type)

      matches.each do |match|
        assert_operator(character_type, :match?, match)
      end

      non_matches.each do |non_match|
        refute_operator(character_type, :match?, non_match)
      end
    end
  end
end
