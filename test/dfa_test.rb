# frozen_string_literal: true

require "test_helper"

module RegularExpression
  class DFATest < Minitest::Test
    def test_alternation
      assert_matches("a|b", "xxx a xxx")
      assert_matches("a|b", "xxx b xxx")
    end

    def test_concatenation
      assert_matches("ab", "xxx ab xxx")
    end

    def test_group
      assert_matches("a(b|c)", "ab")
      assert_matches("a(b|c)", "ac")
    end

    def test_match_any
      assert_matches(".", "a")
      assert_matches(".", "b")
      assert_matches(".", "c")
    end

    def test_optional_quantifier
      assert_matches("a?", "")
      assert_matches("a?", "a")
    end

    def test_range_quantifier_single
      assert_matches("a{3}", "xxx aaa xxx")
    end

    def test_range_quantifier_endless
      assert_matches("a{3,}", "xxx aaa xxx")
      assert_matches("a{3,}", "xxx aaaa xxx")
      assert_matches("a{3,}", "xxx aaaaa xxx")
    end

    def test_range_quantifier_beginless
      assert_matches("a{,3}", "xxx  xxx")
      assert_matches("a{,3}", "xxx a xxx")
      assert_matches("a{,3}", "xxx aa xxx")
      assert_matches("a{,3}", "xxx aaa xxx")
    end

    def test_range_quantifier_range
      assert_matches("a{3,5}", "xxx aaa xxx")
      assert_matches("a{3,5}", "xxx aaaa xxx")
      assert_matches("a{3,5}", "xxx aaaaa xxx")
    end

    def test_star_quantifier
      assert_matches("a*", "xxx  xxx")
      assert_matches("a*", "xxx a xxx")
      assert_matches("a*", "xxx aa xxx")
      assert_matches("a*", "xxx aaa xxx")
    end

    def test_plus_quantifier
      assert_matches("a+", "xxx a xxx")
      assert_matches("a+", "xxx aa xxx")
      assert_matches("a+", "xxx aaa xxx")
    end

    private

    def assert_matches(source, string)
      check_matches(:assert, source, string)
    end

    def refute_matches(source, string)
      check_matches(:refute, source, string)
    end

    def check_matches(predicate, source, string)
      node = Parser.new(source).parse
      nfa = NFA.compile(node)
      dfa = DFA.compile(nfa)

      public_send(predicate, /#{source}/.match?(string))
      public_send(predicate, NFA.match?(nfa, string))
      public_send(predicate, DFA.match?(dfa, string))
      public_send(predicate, Pattern.new(source).match?(string))
    end
  end
end
