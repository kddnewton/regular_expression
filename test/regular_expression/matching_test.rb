# frozen_string_literal: true

require "test_helper"

module RegularExpression
  class MatchingTest < Minitest::Test
    THRESHOLD = 10

    attr_accessor :compiler

    # Test with the interpreter, x86 compiled, and ruby compiled
    def self.test_matching(name, &block)
      define_method(:"test_#{name}_interpreter") do
        @compiler = :interpreter
        instance_eval(&block)
      end

      define_method(:"test_#{name}_x86") do
        @compiler = :x86
        instance_eval(&block)
      end

      define_method(:"test_#{name}_cranelift") do
        @compiler = :cranelift
        instance_eval(&block)
      end

      define_method(:"test_#{name}_ruby") do
        @compiler = :ruby
        instance_eval(&block)
      end

      define_method(:"test_#{name}_profile_x86") do
        @compiler = :profile_x86
        instance_eval(&block)
      end

      define_method(:"test_#{name}_speculative_x86") do
        @compiler = :speculative_x86
        instance_eval(&block)
      end
    end

    test_matching(:basic) do
      assert_matches(%q{abc}, "abc")
      assert_matches(%q{abc}, "!abc")
      assert_matches(%q{,},   ",")
      assert_matches(%q{-},   "-")
    end

    test_matching(:basic_numbers) do
      assert_matches(%q{100}, "100")
      assert_matches(%q{1+},  "11")
    end

    test_matching(:optional) do
      assert_matches(%q{abc?}, "ab")
      assert_matches(%q{abc?}, "abc")
      refute_matches(%q{abc?}, "ac")
    end

    test_matching(:alternation) do
      assert_matches(%q{ab|bc}, "ab")
      assert_matches(%q{ab|bc}, "bc")
      refute_matches(%q{ab|bc}, "ac")
    end

    test_matching(:alternation_backtracking) do
      assert_matches(%q{ab|ac}, "ab")
      assert_matches(%q{ab|ac}, "ac")
      refute_matches(%q{ab|ac}, "bc")
    end

    test_matching(:multicharacter_backtracking) do
      skip
      assert_matches(%q{a?a?a?aaa}, "aaaaa")
    end

    test_matching(:larger_strings) do
      assert_matches(%Q{#{'a' * 50}b}, "#{'a' * 50}b")
    end

    test_matching(:begin_anchor_caret) do
      assert_matches(%q{^abc}, "abc")
      refute_matches(%q{^abc}, "!abc")
    end

    test_matching(:begin_anchor_a) do
      assert_matches(%q{\Aabc}, "abc")
      refute_matches(%q{\Aabc}, "!abc")
    end

    test_matching(:end_anchor_dollar_sign) do
      assert_matches(%q{abc$}, "abc")
      refute_matches(%q{abc$}, "abc!")
    end

    test_matching(:end_anchor_z) do
      assert_matches(%q{abc\z}, "abc")
      refute_matches(%q{abc\z}, "abc!")
    end

    test_matching(:ranges_exact) do
      assert_matches(%q{a{2}}, "aa")
      refute_matches(%q{a{2}}, "a")
    end

    test_matching(:ranges_minimum) do
      assert_matches(%q{a{2,}}, "aa")
      assert_matches(%q{a{2,}}, "aaaa")
      refute_matches(%q{a{2,}}, "a")
    end

    test_matching(:ranges_minimum_and_maximum) do
      assert_matches(%q{a{2,5}}, "aaa")
      assert_matches(%q{a{2,5}}, "aaaaa")
      refute_matches(%q{a{2,5}}, "a")
      assert_matches(%q{a{11,15}}, "a" * 11)
    end

    test_matching(:ranges_maximum) do
      assert_matches("ab{,5}c", "ac")
      assert_matches("ab{,5}c", "abbbbbc")
      refute_matches("ab{,5}c", "abbbbbbc")
    end

    test_matching(:star) do
      assert_matches(%q{a*}, "")
      assert_matches(%q{a*}, "a")
      assert_matches(%q{a*}, "aa")
    end

    test_matching(:plus) do
      assert_matches(%q{a+}, "a")
      assert_matches(%q{a+}, "aa")
      refute_matches(%q{a+}, "")
    end

    test_matching(:character_range) do
      assert_matches(%q{[a-z]}, "a")
      assert_matches(%q{[a-z]}, "z")
      refute_matches(%q{[a-z]}, "A")
    end

    test_matching(:character_set) do
      assert_matches(%q{[abc]}, "a")
      assert_matches(%q{[abc]}, "c")
      assert_matches(%q{[a,c]}, ",")
      assert_matches(%q{[\w]}, "a")
      refute_matches(%q{[abc]}, "d")
    end

    test_matching(:character_class_d) do
      assert_matches(%q{\d}, "0")
      refute_matches(%q{\d}, "a")
    end

    test_matching(:character_class_d_invert) do
      assert_matches(%q{\D}, "a")
      refute_matches(%q{\D}, "0")
    end

    test_matching(:character_class_w) do
      assert_matches(%q{\w}, "a")
      refute_matches(%q{\w}, "!")
    end

    test_matching(:character_class_w_invert) do
      assert_matches(%q{\W}, "!")
      refute_matches(%q{\W}, "a")
    end

    test_matching(:character_class_h) do
      assert_matches(%q{\h}, "0")
      assert_matches(%q{\h}, "a")
      refute_matches(%q{\h}, "!")
    end

    test_matching(:character_class_h_invert) do
      assert_matches(%q{\H}, "!")
      assert_matches(%q{\H}, "^")
      refute_matches(%q{\H}, "a")
    end

    test_matching(:character_class_s) do
      assert_matches(%q{\s}, " ")
      assert_matches(%q{\s}, "\n")
      assert_matches(%q{\s}, "\t")
      assert_matches(%q{\s}, "\f")
      assert_matches(%q{\s}, "\r")
      assert_matches(%q{\s}, "\v")
      refute_matches(%q{\s}, "!")
    end

    test_matching(:character_class_s_invert) do
      refute_matches(%q{\S}, " ")
      refute_matches(%q{\S}, "\t")
      refute_matches(%q{\S}, "\n")
      refute_matches(%q{\S}, "\f")
      refute_matches(%q{\S}, "\v")
      assert_matches(%q{\S}, "a")
    end

    test_matching(:character_group) do
      assert_matches(%q{[a-ce]}, "b")
      assert_matches(%q{[a-ce]}, "e")
      refute_matches(%q{[a-ce]}, "d")
    end

    test_matching(:character_set_inverted) do
      assert_matches(%q{[^a-ce]}, "d")
      assert_matches(%q{[^a-ce]}, "f")
      refute_matches(%q{[^a-ce]}, "a")
    end

    test_matching(:character_type_alnum) do
      assert_matches(%q{[[:alnum:]]}, "a")
      assert_matches(%q{[[:alnum:]]}, "0")
      refute_matches(%q{[[:alnum:]]}, "!")
    end

    test_matching(:character_property_alnum) do
      assert_matches(%q{\p{Alnum}}, "a")
      assert_matches(%q{\p{Alnum}}, "0")
      refute_matches(%q{\p{Alnum}}, "!")
    end

    test_matching(:character_type_alpha) do
      assert_matches(%q{[[:alpha:]]}, "a")
      assert_matches(%q{[[:alpha:]]}, "z")
      refute_matches(%q{[[:alpha:]]}, "0")
    end

    test_matching(:character_property_alpha) do
      assert_matches(%q{\p{Alpha}}, "a")
      assert_matches(%q{\p{Alpha}}, "z")
      refute_matches(%q{\p{Alpha}}, "0")
    end

    test_matching(:character_type_lower) do
      assert_matches(%q{[[:lower:]]}, "a")
      assert_matches(%q{[[:lower:]]}, "z")
      refute_matches(%q{[[:lower:]]}, "A")
    end

    test_matching(:character_property_lower) do
      assert_matches(%q{\p{Lower}}, "a")
      assert_matches(%q{\p{Lower}}, "z")
      refute_matches(%q{\p{Lower}}, "A")
    end

    test_matching(:character_type_upper) do
      assert_matches(%q{[[:upper:]]}, "A")
      assert_matches(%q{[[:upper:]]}, "Z")
      refute_matches(%q{[[:upper:]]}, "a")
    end

    test_matching(:character_property_upper) do
      assert_matches(%q{\p{Upper}}, "A")
      assert_matches(%q{\p{Upper}}, "Z")
      refute_matches(%q{\p{Upper}}, "a")
    end

    test_matching(:period) do
      assert_matches(%q{.}, "a")
      assert_matches(%q{.}, "z")
      refute_matches(%q{.}, "")
    end

    test_matching(:group) do
      assert_matches(%q{a(b|c)}, "ab")
      assert_matches(%q{a(b|c)}, "ac")
      refute_matches(%q{a(b|c)}, "a")
    end

    test_matching(:group_quantifier) do
      assert_matches(%q{a(b|c){2}}, "abc")
      assert_matches(%q{a(b|c){2}}, "acb")
      refute_matches(%q{a(b|c){2}}, "ab")
    end

    test_matching(:escaped_backslash) do
      assert_matches(%q{\\\\s}, "\\\\s")
      refute_matches(%q{\\\\s}, " ")
    end

    test_matching(:escaped_plus) do
      assert_matches(%q{a\\+}, "a+")
      refute_matches(%q{a\\+}, "a")
    end

    test_matching(:positive_lookahead) do
      assert_matches("a(?=b)", "ab")
      assert_matches("a(?=b)", "aab")
      refute_matches("a(?=b)", "aa")
    end

    test_matching(:negative_lookahead) do
      assert_matches("a(?!b)", "aa")
      assert_matches("a(?!b)", "ba")
      refute_matches("a(?!b)", "ab")
    end

    def test_extended_mode
      # First just check that this pattern actually works
      pattern = Pattern.new(%q{\A[[:digit:]]+(\.[[:digit:]]+)?\z})
      assert_operator(pattern, :match?, "3.1")

      # Now check that the right tokens were ignored
      pattern = Pattern.new(<<~REGEXP, "x")
        \\A
        [[:digit:]]+ # 1 or more digits before the decimal point
        (\\.         # Decimal point
        [[:digit:]]+ # 1 or more digits after the decimal point
        )?           # The decimal point and following digits are optional
        \\z
      REGEXP

      assert_operator(pattern, :match?, "3.1")
    end

    def test_raises_syntax_errors
      assert_raises(Lexer::Error) do
        Parser.new.parse("\u0000")
      end
    end

    def test_raises_parse_errors
      assert_raises(Racc::ParseError) do
        Parser.new.parse(%q{(})
      end
    end

    def test_debug
      source = %q{^\A(a?|b{2,3}|[cd]*|[e-g]+|[^h-jk]|\d\D\w\W\h\s|.)\z$}

      ast = Parser.new.parse(source)
      nfa = NFA.build(ast)
      bytecode = Bytecode.compile(nfa)
      cfg = CFG.build(bytecode)
      schedule = Scheduler.schedule(cfg)

      interpreter = Interpreter.new(bytecode)
      assert_kind_of(Proc, interpreter.to_proc)

      assert_kind_of(String, bytecode.dump)
      assert_kind_of(String, cfg.dump)
      assert_kind_of(String, Scheduler.dump(cfg, schedule))

      assert_kind_of(String, AST.to_dot(ast))
      assert_kind_of(String, NFA.to_dot(nfa))
      assert_kind_of(String, CFG.to_dot(cfg))
    end

    def test_speculation
      threshold = 100
      compiled = 0
      deoptimized = 0

      pattern = Pattern.new("a(bcde)?f")

      pattern.define_singleton_method :compiled do
        compiled += 1
      end

      pattern.define_singleton_method :deoptimized do
        deoptimized += 1
      end

      pattern.profile threshold: threshold, speculative: true

      assert_equal 0, compiled
      assert_equal 0, deoptimized
      (threshold * 2).times do
        assert_operator pattern, :match?, "af"
      end
      assert_equal 1, compiled
      assert_equal 0, deoptimized

      assert_equal 1, compiled
      assert_equal 0, deoptimized
      (threshold * 2).times do
        assert_operator pattern, :match?, "abcdef"
      end
      assert_equal 2, compiled
      assert_equal 1, deoptimized
    end

    private

    def assertion_pattern(source)
      pattern = Pattern.new(source)

      case compiler
      when :x86
        pattern.compile(compiler: Compiler::X86)
      when :ruby
        pattern.compile(compiler: Compiler::Ruby)
      when :profile_x86
        pattern.profile(compiler: Compiler::Ruby, threshold: THRESHOLD)
      when :speculative_x86
        pattern.profile(compiler: Compiler::Ruby, threshold: THRESHOLD, speculative: true)
      when :cranelift
        pattern.compile(compiler: Compiler::Cranelift)
      end

      pattern
    end

    def assert_matches(source, value)
      message = "Expected /#{source}/ to match #{value.inspect} (#{compiler})"
      pattern = assertion_pattern(source)
      (THRESHOLD * 2).times do
        pattern.match?(value)
      end
      assert_operator pattern, :match?, value, message
    end

    def refute_matches(source, value)
      message = "Expected /#{source}/ to not match #{value.inspect} (#{compiler})"
      pattern = assertion_pattern(source)
      (THRESHOLD * 2).times do
        pattern.match?(value)
      end
      refute_operator pattern, :match?, value, message
    end
  end
end
