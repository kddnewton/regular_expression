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

  def test_alternation_backtracking
    assert_matches("ab|ac", "ab")
    assert_matches("ab|ac", "ac")
    refute_matches("ab|ac", "bc")
  end

  def test_begin_anchor_caret
    assert_matches("^abc", "abc")
    refute_matches("^abc", "!abc")
  end

  def test_begin_anchor_a
    assert_matches("\\Aabc", "abc")
    refute_matches("\\Aabc", "!abc")
  end

  def test_end_anchor_dollar_sign
    assert_matches("abc$", "abc")
    refute_matches("abc$", "abc!")
  end

  def test_end_anchor_z
    assert_matches("abc\\z", "abc")
    refute_matches("abc\\z", "abc!")
  end

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

  def test_ranges_maximum
    assert_matches("ab{,5}c", "ac")
    assert_matches("ab{,5}c", "abbbbbc")
    refute_matches("ab{,5}c", "abbbbbbc")
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

  def test_character_range
    assert_matches("[a-z]", "a")
    assert_matches("[a-z]", "z")
    refute_matches("[a-z]", "A")
  end

  def test_character_set
    assert_matches("[abc]", "a")
    assert_matches("[abc]", "c")
    refute_matches("[abc]", "d")
  end

  def test_character_class_d
    assert_matches("\\d", "0")
    refute_matches("\\d", "a")
  end

  def test_character_class_d_invert
    assert_matches("\\D", "a")
    refute_matches("\\D", "0")
  end

  def test_character_class_w
    assert_matches("\\w", "a")
    refute_matches("\\w", "!")
  end

  def test_character_class_w_invert
    assert_matches("\\W", "!")
    refute_matches("\\W", "a")
  end

  def test_character_group
    assert_matches("[a-ce]", "b")
    assert_matches("[a-ce]", "e")
    refute_matches("[a-ce]", "d")
  end

  def test_character_set_inverted
    assert_matches("[^a-ce]", "d")
    assert_matches("[^a-ce]", "f")
    refute_matches("[^a-ce]", "a")
  end

  def test_period
    assert_matches(".", "a")
    assert_matches(".", "z")
    refute_matches(".", "")
  end

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

  def test_raises_syntax_errors
    assert_raises(SyntaxError) do
      RegularExpression::Parser.new.parse("\u0000")
    end
  end

  def test_raises_parse_errors
    assert_raises(Racc::ParseError) do
      RegularExpression::Parser.new.parse("(")
    end
  end

  def test_debug
    source = "^\\A(a?|b{2,3}|[cd]*|[e-g]+|[^h-jk]|\\d\\D\\w\\W|.)\\z$"

    ast = RegularExpression::Parser.new.parse(source)
    nfa = ast.to_nfa
    bytecode = RegularExpression::Bytecode.compile(nfa)
    cfg = RegularExpression::CFG.build(bytecode)

    interpreter = RegularExpression::Interpreter.new(bytecode)
    assert_kind_of(Proc, interpreter.to_proc)

    assert_kind_of(String, bytecode.dump)
    assert_kind_of(String, cfg.dump)

    assert_kind_of(String, RegularExpression::AST.to_dot(ast))
    assert_kind_of(String, RegularExpression::NFA.to_dot(nfa))
    assert_kind_of(String, RegularExpression::CFG.to_dot(cfg))
  end

  private

  def assert_matches(source, value)
    message = "Expected /#{source}/ to match #{value.inspect}"

    pattern = RegularExpression::Pattern.new(source)
    assert_operator pattern, :match?, value, message

    pattern.compile(compiler: RegularExpression::Compiler::X86)
    assert_operator pattern, :match?, value, "#{message} (native)"

    pattern.compile(compiler: RegularExpression::Compiler::Ruby)
    assert_operator pattern, :match?, value, "#{message} (ruby)"
  end

  def refute_matches(source, value)
    message = "Expected /#{source}/ to not match #{value.inspect}"

    pattern = RegularExpression::Pattern.new(source)
    refute_operator pattern, :match?, value, message

    pattern.compile(compiler: RegularExpression::Compiler::X86)
    refute_operator pattern, :match?, value, "#{message} (native)"

    pattern.compile(compiler: RegularExpression::Compiler::Ruby)
    refute_operator pattern, :match?, value, "#{message} (ruby)"
  end
end
