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

    def test_match_any
      assert_matches(".", "a")
      assert_matches(".", "b")
      assert_matches(".", "c")
    end

    def test_optional_quantifier
      assert_matches("a?", "")
      assert_matches("a?", "a")
    end

    def test_range_quantifier
      assert_matches("a{3}", "xxx aaa xxx")
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
      node = Parser.new(source).parse
      nfa = NFA.compile(node)
      dfa = DFA.compile(nfa)

      assert(/#{source}/.match?(string))
      assert(NFA.match?(nfa, string))
      assert(DFA.match?(dfa, string))
      assert(Pattern.new(source).match?(string))
    end
  end
end
