# frozen_string_literal: true

require "test_helper"

module RegularExpression
  class FlagsTest < Minitest::Test
    def test_parse_accepts_string
      assert(Flags.parse("x").extended?)
    end

    def test_initializer_accepts_bit_flags
      assert(Flags.new(Regexp::EXTENDED).extended?)
    end

    def test_extended
      assert(Flags.new(Regexp::EXTENDED).extended?)
      refute(Flags.new.extended?)
    end

    def test_unknown_flag_raises
      assert_raises(ArgumentError) do
        Flags.parse("z")
      end
    end
  end
end
