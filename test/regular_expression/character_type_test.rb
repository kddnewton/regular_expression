# frozen_string_literal: true

require "test_helper"

module RegularExpression
  class CharacterTypeTest < Minitest::Test
    def test_alnum
      character_type = CharacterType.new("alnum")

      assert_operator(character_type, :match?, "a")
      assert_operator(character_type, :match?, "0")
      refute_operator(character_type, :match?, "!")
    end

    def test_alpha
      character_type = CharacterType.new("alpha")

      assert_operator(character_type, :match?, "a")
      assert_operator(character_type, :match?, "z")
      refute_operator(character_type, :match?, "0")
    end

    def test_lower
      character_type = CharacterType.new("lower")

      assert_operator(character_type, :match?, "a")
      assert_operator(character_type, :match?, "z")
      refute_operator(character_type, :match?, "A")
    end

    def test_upper
      character_type = CharacterType.new("upper")

      assert_operator(character_type, :match?, "A")
      assert_operator(character_type, :match?, "Z")
      refute_operator(character_type, :match?, "a")
    end
  end
end
