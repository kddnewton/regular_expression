# frozen_string_literal: true

require "test_helper"

class RegularExpressionTest < Minitest::Test
  def test_basic
    assert_matches("abc", "abc")
    assert_matches("abc", "!abc")
  end

  def test_optional
    assert_matches("abc?", "ab")
    assert_matches("abc?", "abc")
    refute_matches("abc?", "ac")
  end

  def test_alternation
    assert_matches("ab|bc", "ab")
    assert_matches("ab|bc", "bc")
    refute_matches("ab|bc", "ac")
  end

  # def test_begin_anchor_caret
  #   assert_matches("^abc", "abc")
  #   refute_matches("^abc", "!abc")
  # end

  # def test_begin_anchor_a
  #   assert_matches("\\Aabc", "abc")
  #   refute_matches("\\Aabc", "!abc")
  # end

  # def test_end_anchor_dollar_sign
  #   assert_matches("abc$", "abc")
  #   refute_matches("abc$", "abc!")
  # end

  # def test_end_anchor_z
  #   assert_matches("abc\\z", "abc")
  #   refute_matches("abc\\z", "abc!")
  # end

  def test_ranges_exact
    assert_matches("a{2}", "aa")
    refute_matches("a{2}", "a")
  end

  def test_ranges_minimum
    assert_matches("a{2,}", "aa")
    assert_matches("a{2,}", "aaaa")
    refute_matches("a{2,}", "a")
  end

  def test_ranges_minimum_and_maximum
    assert_matches("a{2,5}", "aaa")
    assert_matches("a{2,5}", "aaaaa")
    refute_matches("a{2,5}", "a")
  end

  def test_star
    assert_matches("a*", "")
    assert_matches("a*", "a")
    assert_matches("a*", "aa")
  end

  def test_plus
    assert_matches("a+", "a")
    assert_matches("a+", "aa")
    refute_matches("a+", "")
  end

  # def test_character_range
  #   assert_matches("[a-z]", "a")
  #   assert_matches("[a-z]", "z")
  #   refute_matches("[a-z]", "A")
  # end

  # def test_character_set
  #   assert_matches("[abc]", "a")
  #   assert_matches("[abc]", "c")
  #   refute_matches("[abc]", "d")
  # end

  # def test_period
  #   assert_matches(".", "a")
  #   assert_matches(".", "z")
  #   refute_matches(".", "")
  # end

  def test_group
    assert_matches("a(b|c)", "ab")
    assert_matches("a(b|c)", "ac")
    refute_matches("a(b|c)", "a")
  end

  def test_group_quantifier
    assert_matches("a(b|c){2}", "abc")
    assert_matches("a(b|c){2}", "acb")
    refute_matches("a(b|c){2}", "ab")
  end

  private

  def assert_matches(pattern, value)
    assert_operator RegularExpression::Pattern.new(pattern), :match?, value
  end

  def refute_matches(pattern, value)
    refute_operator RegularExpression::Pattern.new(pattern), :match?, value
  end
end
