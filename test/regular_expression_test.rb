# frozen_string_literal: true

require "test_helper"

class RegularExpressionTest < Minitest::Test
  def test_basic
    assert_matches(%q{abc}, "abc")
    assert_matches(%q{abc}, "!abc")
    assert_matches(%q{,},   ",")
    assert_matches(%q{-},   "-")
  end

  def test_basic_numbers
    assert_matches(%q{100}, "100")
    assert_matches(%q{1+},  "11")
  end

  def test_optional
    assert_matches(%q{abc?}, "ab")
    assert_matches(%q{abc?}, "abc")
    refute_matches(%q{abc?}, "ac")
  end

  def test_alternation
    assert_matches(%q{ab|bc}, "ab")
    assert_matches(%q{ab|bc}, "bc")
    refute_matches(%q{ab|bc}, "ac")
  end

  def test_alternation_backtracking
    assert_matches(%q{ab|ac}, "ab")
    assert_matches(%q{ab|ac}, "ac")
    refute_matches(%q{ab|ac}, "bc")
  end

  def test_begin_anchor_caret
    assert_matches(%q{^abc}, "abc")
    refute_matches(%q{^abc}, "!abc")
  end

  def test_begin_anchor_a
    assert_matches(%q{\Aabc}, "abc")
    refute_matches(%q{\Aabc}, "!abc")
  end

  def test_end_anchor_dollar_sign
    assert_matches(%q{abc$}, "abc")
    refute_matches(%q{abc$}, "abc!")
  end

  def test_end_anchor_z
    assert_matches(%q{abc\z}, "abc")
    refute_matches(%q{abc\z}, "abc!")
  end

  def test_ranges_exact
    assert_matches(%q{a{2}}, "aa")
    refute_matches(%q{a{2}}, "a")
  end

  def test_ranges_minimum
    assert_matches(%q{a{2,}}, "aa")
    assert_matches(%q{a{2,}}, "aaaa")
    refute_matches(%q{a{2,}}, "a")
  end

  def test_ranges_minimum_and_maximum
    assert_matches(%q{a{2,5}}, "aaa")
    assert_matches(%q{a{2,5}}, "aaaaa")
    refute_matches(%q{a{2,5}}, "a")
    assert_matches(%q{a{11,15}},  "a" * 11)
  end

  def test_ranges_maximum
    assert_matches("ab{,5}c", "ac")
    assert_matches("ab{,5}c", "abbbbbc")
    refute_matches("ab{,5}c", "abbbbbbc")
  end

  def test_star
    assert_matches(%q{a*}, "")
    assert_matches(%q{a*}, "a")
    assert_matches(%q{a*}, "aa")
  end

  def test_plus
    assert_matches(%q{a+}, "a")
    assert_matches(%q{a+}, "aa")
    refute_matches(%q{a+}, "")
  end

  def test_character_range
    assert_matches(%q{[a-z]}, "a")
    assert_matches(%q{[a-z]}, "z")
    refute_matches(%q{[a-z]}, "A")
  end

  def test_character_set
    assert_matches(%q{[abc]}, "a")
    assert_matches(%q{[abc]}, "c")
    assert_matches(%q{[a,c]}, ",")
    assert_matches(%q{[\w]}, "a")
    refute_matches(%q{[abc]}, "d")
  end

  def test_character_class_d
    assert_matches(%q{\d}, "0")
    refute_matches(%q{\d}, "a")
  end

  def test_character_class_d_invert
    assert_matches(%q{\D}, "a")
    refute_matches(%q{\D}, "0")
  end

  def test_character_class_w
    assert_matches(%q{\w}, "a")
    refute_matches(%q{\w}, "!")
  end

  def test_character_class_w_invert
    assert_matches(%q{\W}, "!")
    refute_matches(%q{\W}, "a")
  end

  def test_character_class_h
    assert_matches(%q{\h}, "0")
    assert_matches(%q{\h}, "a")
    refute_matches(%q{\h}, "!")
  end

  def test_character_class_h_invert
    assert_matches(%q{\H}, "!")
    assert_matches(%q{\H}, "^")
    refute_matches(%q{\H}, "a")
  end

  def test_character_class_s
    assert_matches(%q{\s}, " ")
    assert_matches(%q{\s}, "\n")
    assert_matches(%q{\s}, "\t")
    assert_matches(%q{\s}, "\f")
    assert_matches(%q{\s}, "\r")
    assert_matches(%q{\s}, "\v")
    refute_matches(%q{\s}, "!")
  end

  def test_character_class_s_invert
    refute_matches(%q{\S}, " ")
    refute_matches(%q{\S}, "\t")
    refute_matches(%q{\S}, "\n")
    refute_matches(%q{\S}, "\f")
    refute_matches(%q{\S}, "\v")
    assert_matches(%q{\S}, "a")
  end

  def test_character_group
    assert_matches(%q{[a-ce]}, "b")
    assert_matches(%q{[a-ce]}, "e")
    refute_matches(%q{[a-ce]}, "d")
  end

  def test_character_set_inverted
    assert_matches(%q{[^a-ce]}, "d")
    assert_matches(%q{[^a-ce]}, "f")
    refute_matches(%q{[^a-ce]}, "a")
  end

  def test_character_type_alnum
    assert_matches(%q{[[:alnum:]]}, "a")
    assert_matches(%q{[[:alnum:]]}, "0")
    refute_matches(%q{[[:alnum:]]}, "!")
  end

  def test_character_type_alpha
    assert_matches(%q{[[:alpha:]]}, "a")
    assert_matches(%q{[[:alpha:]]}, "z")
    refute_matches(%q{[[:alpha:]]}, "0")
  end

  def test_character_type_lower
    assert_matches(%q{[[:lower:]]}, "a")
    assert_matches(%q{[[:lower:]]}, "z")
    refute_matches(%q{[[:lower:]]}, "A")
  end

  def test_character_type_upper
    assert_matches(%q{[[:upper:]]}, "A")
    assert_matches(%q{[[:upper:]]}, "Z")
    refute_matches(%q{[[:upper:]]}, "a")
  end

  def test_period
    assert_matches(%q{.}, "a")
    assert_matches(%q{.}, "z")
    refute_matches(%q{.}, "")
  end

  def test_group
    assert_matches(%q{a(b|c)}, "ab")
    assert_matches(%q{a(b|c)}, "ac")
    refute_matches(%q{a(b|c)}, "a")
  end

  def test_group_quantifier
    assert_matches(%q{a(b|c){2}}, "abc")
    assert_matches(%q{a(b|c){2}}, "acb")
    refute_matches(%q{a(b|c){2}}, "ab")
  end

  def test_escaped_backslash
    assert_matches(%q{\\\\s}, "\\\\s")
    refute_matches(%q{\\\\s}, " ")
  end

  def test_escaped_plus
    assert_matches(%q{a\\+}, "a+")
    refute_matches(%q{a\\+}, "a")
  end

  def test_raises_syntax_errors
    assert_raises(SyntaxError) do
      RegularExpression::Parser.new.parse("\u0000")
    end
  end

  def test_raises_parse_errors
    assert_raises(Racc::ParseError) do
      RegularExpression::Parser.new.parse(%q{(})
    end
  end

  def test_debug
    source = %q{^\A(a?|b{2,3}|[cd]*|[e-g]+|[^h-jk]|\d\D\w\W\h\s|.)\z$}

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
