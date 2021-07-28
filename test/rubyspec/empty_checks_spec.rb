require_relative "../rubyspec_helper"

describe "empty checks in Regexps" do

  it "allow extra empty iterations" do
    RegularExpression::Pattern.new("()?").match("").to_a.should == ["", ""]
    RegularExpression::Pattern.new("(a*)?").match("").to_a.should == ["", ""]
    RegularExpression::Pattern.new("(a*)*").match("").to_a.should == ["", ""]
    # The bounds are high to avoid DFA-based matchers in implementations
    # and to check backtracking behavior.
    RegularExpression::Pattern.new("(?:a|()){500,1000}").match("a" * 500).to_a.should == ["a" * 500, ""]

    # Variations with non-greedy loops.
    RegularExpression::Pattern.new("()??").match("").to_a.should == ["", nil]
    RegularExpression::Pattern.new("(a*?)?").match("").to_a.should == ["", ""]
    RegularExpression::Pattern.new("(a*)??").match("").to_a.should == ["", nil]
    RegularExpression::Pattern.new("(a*?)??").match("").to_a.should == ["", nil]
    RegularExpression::Pattern.new("(a*?)*").match("").to_a.should == ["", ""]
    RegularExpression::Pattern.new("(a*)*?").match("").to_a.should == ["", nil]
    RegularExpression::Pattern.new("(a*?)*?").match("").to_a.should == ["", nil]
  end

  it "allow empty iterations in the middle of a loop" do
    # One empty iteration between a's and b's.
    RegularExpression::Pattern.new("(a|\\2b|())*").match("aaabbb").to_a.should == ["aaabbb", "", ""]
    RegularExpression::Pattern.new("(a|\\2b|()){2,4}").match("aaabbb").to_a.should == ["aaa", "", ""]

    # Two empty iterations between a's and b's.
    RegularExpression::Pattern.new("(a|\\2b|\\3()|())*").match("aaabbb").to_a.should == ["aaabbb", "", "", ""]
    RegularExpression::Pattern.new("(a|\\2b|\\3()|()){2,4}").match("aaabbb").to_a.should == ["aaa", "", nil, ""]

    # Check that the empty iteration correctly updates the loop counter.
    RegularExpression::Pattern.new("(a|\\2b|()){20,24}").match("a" * 20 + "b" * 5).to_a.should == ["a" * 20 + "b" * 3, "b", ""]

    # Variations with non-greedy loops.
    RegularExpression::Pattern.new("(a|\\2b|())*?").match("aaabbb").to_a.should == ["", nil, nil]
    RegularExpression::Pattern.new("(a|\\2b|()){2,4}").match("aaabbb").to_a.should == ["aaa", "", ""]
    RegularExpression::Pattern.new("(a|\\2b|\\3()|())*?").match("aaabbb").to_a.should == ["", nil, nil, nil]
    RegularExpression::Pattern.new("(a|\\2b|\\3()|()){2,4}").match("aaabbb").to_a.should == ["aaa", "", nil, ""]
    RegularExpression::Pattern.new("(a|\\2b|()){20,24}").match("a" * 20 + "b" * 5).to_a.should == ["a" * 20 + "b" * 3, "b", ""]
  end

  it "make the Regexp proceed past the quantified expression on failure" do
    # If the contents of the ()* quantified group are empty (i.e., they fail
    # the empty check), the loop will abort. It will not try to backtrack
    # and try other alternatives (e.g. matching the "a") like in other Regexp
    # dialects such as ECMAScript.
    RegularExpression::Pattern.new("(?:|a)*").match("aaa").to_a.should == [""]
    RegularExpression::Pattern.new("(?:()|a)*").match("aaa").to_a.should == ["", ""]
    RegularExpression::Pattern.new("(|a)*").match("aaa").to_a.should == ["", ""]
    RegularExpression::Pattern.new("(()|a)*").match("aaa").to_a.should == ["", "", ""]

    # Same expressions, but with backreferences, to force the use of non-DFA-based
    # engines.
    RegularExpression::Pattern.new("()\\1(?:|a)*").match("aaa").to_a.should == ["", ""]
    RegularExpression::Pattern.new("()\\1(?:()|a)*").match("aaa").to_a.should == ["", "", ""]
    RegularExpression::Pattern.new("()\\1(|a)*").match("aaa").to_a.should == ["", "", ""]
    RegularExpression::Pattern.new("()\\1(()|a)*").match("aaa").to_a.should == ["", "", "", ""]

    # Variations with other zero-width contents of the quantified
    # group: backreferences, capture groups, lookarounds
    RegularExpression::Pattern.new("()(?:\\1|a)*").match("aaa").to_a.should == ["", ""]
    RegularExpression::Pattern.new("()(?:()\\1|a)*").match("aaa").to_a.should == ["", "", ""]
    RegularExpression::Pattern.new("()(?:(\\1)|a)*").match("aaa").to_a.should == ["", "", ""]
    RegularExpression::Pattern.new("()(?:\\1()|a)*").match("aaa").to_a.should == ["", "", ""]
    RegularExpression::Pattern.new("()(\\1|a)*").match("aaa").to_a.should == ["", "", ""]
    RegularExpression::Pattern.new("()(()\\1|a)*").match("aaa").to_a.should == ["", "", "", ""]
    RegularExpression::Pattern.new("()((\\1)|a)*").match("aaa").to_a.should == ["", "", "", ""]
    RegularExpression::Pattern.new("()(\\1()|a)*").match("aaa").to_a.should == ["", "", "", ""]

    RegularExpression::Pattern.new("(?:(?=a)|a)*").match("aaa").to_a.should == [""]
    RegularExpression::Pattern.new("(?:(?=a)()|a)*").match("aaa").to_a.should == ["", ""]
    RegularExpression::Pattern.new("(?:()(?=a)|a)*").match("aaa").to_a.should == ["", ""]
    RegularExpression::Pattern.new("(?:((?=a))|a)*").match("aaa").to_a.should == ["", ""]
    RegularExpression::Pattern.new("()\\1(?:(?=a)|a)*").match("aaa").to_a.should == ["", ""]
    RegularExpression::Pattern.new("()\\1(?:(?=a)()|a)*").match("aaa").to_a.should == ["", "", ""]
    RegularExpression::Pattern.new("()\\1(?:()(?=a)|a)*").match("aaa").to_a.should == ["", "", ""]
    RegularExpression::Pattern.new("()\\1(?:((?=a))|a)*").match("aaa").to_a.should == ["", "", ""]

    # Variations with non-greedy loops.
    RegularExpression::Pattern.new("(?:|a)*?").match("aaa").to_a.should == [""]
    RegularExpression::Pattern.new("(?:()|a)*?").match("aaa").to_a.should == ["", nil]
    RegularExpression::Pattern.new("(|a)*?").match("aaa").to_a.should == ["", nil]
    RegularExpression::Pattern.new("(()|a)*?").match("aaa").to_a.should == ["", nil, nil]

    RegularExpression::Pattern.new("()\\1(?:|a)*?").match("aaa").to_a.should == ["", ""]
    RegularExpression::Pattern.new("()\\1(?:()|a)*?").match("aaa").to_a.should == ["", "", nil]
    RegularExpression::Pattern.new("()\\1(|a)*?").match("aaa").to_a.should == ["", "", nil]
    RegularExpression::Pattern.new("()\\1(()|a)*?").match("aaa").to_a.should == ["", "", nil, nil]

    RegularExpression::Pattern.new("()(?:\\1|a)*?").match("aaa").to_a.should == ["", ""]
    RegularExpression::Pattern.new("()(?:()\\1|a)*?").match("aaa").to_a.should == ["", "", nil]
    RegularExpression::Pattern.new("()(?:(\\1)|a)*?").match("aaa").to_a.should == ["", "", nil]
    RegularExpression::Pattern.new("()(?:\\1()|a)*?").match("aaa").to_a.should == ["", "", nil]
    RegularExpression::Pattern.new("()(\\1|a)*?").match("aaa").to_a.should == ["", "", nil]
    RegularExpression::Pattern.new("()(()\\1|a)*?").match("aaa").to_a.should == ["", "", nil, nil]
    RegularExpression::Pattern.new("()((\\1)|a)*?").match("aaa").to_a.should == ["", "", nil, nil]
    RegularExpression::Pattern.new("()(\\1()|a)*?").match("aaa").to_a.should == ["", "", nil, nil]

    RegularExpression::Pattern.new("(?:(?=a)|a)*?").match("aaa").to_a.should == [""]
    RegularExpression::Pattern.new("(?:(?=a)()|a)*?").match("aaa").to_a.should == ["", nil]
    RegularExpression::Pattern.new("(?:()(?=a)|a)*?").match("aaa").to_a.should == ["", nil]
    RegularExpression::Pattern.new("(?:((?=a))|a)*?").match("aaa").to_a.should == ["", nil]
    RegularExpression::Pattern.new("()\\1(?:(?=a)|a)*?").match("aaa").to_a.should == ["", ""]
    RegularExpression::Pattern.new("()\\1(?:(?=a)()|a)*?").match("aaa").to_a.should == ["", "", nil]
    RegularExpression::Pattern.new("()\\1(?:()(?=a)|a)*?").match("aaa").to_a.should == ["", "", nil]
    RegularExpression::Pattern.new("()\\1(?:((?=a))|a)*?").match("aaa").to_a.should == ["", "", nil]
  end

  it "shouldn't cause the Regexp parser to get stuck in a loop" do
    RegularExpression::Pattern.new("(|a|\\2b|())*").match("aaabbb").to_a.should == ["", "", nil]
    RegularExpression::Pattern.new("(a||\\2b|())*").match("aaabbb").to_a.should == ["aaa", "", nil]
    RegularExpression::Pattern.new("(a|\\2b||())*").match("aaabbb").to_a.should == ["aaa", "", nil]
    RegularExpression::Pattern.new("(a|\\2b|()|)*").match("aaabbb").to_a.should == ["aaabbb", "", ""]
    RegularExpression::Pattern.new("(()|a|\\3b|())*").match("aaabbb").to_a.should == ["", "", "", nil]
    RegularExpression::Pattern.new("(a|()|\\3b|())*").match("aaabbb").to_a.should == ["aaa", "", "", nil]
    RegularExpression::Pattern.new("(a|\\2b|()|())*").match("aaabbb").to_a.should == ["aaabbb", "", "", nil]
    RegularExpression::Pattern.new("(a|\\3b|()|())*").match("aaabbb").to_a.should == ["aaa", "", "", nil]
    RegularExpression::Pattern.new("(a|()|())*").match("aaa").to_a.should == ["aaa", "", "", nil]
    RegularExpression::Pattern.new("^(()|a|())*$").match("aaa").to_a.should == ["aaa", "", "", nil]

    # Variations with non-greedy loops.
    RegularExpression::Pattern.new("(|a|\\2b|())*?").match("aaabbb").to_a.should == ["", nil, nil]
    RegularExpression::Pattern.new("(a||\\2b|())*?").match("aaabbb").to_a.should == ["", nil, nil]
    RegularExpression::Pattern.new("(a|\\2b||())*?").match("aaabbb").to_a.should == ["", nil, nil]
    RegularExpression::Pattern.new("(a|\\2b|()|)*?").match("aaabbb").to_a.should == ["", nil, nil]
    RegularExpression::Pattern.new("(()|a|\\3b|())*?").match("aaabbb").to_a.should == ["", nil, nil, nil]
    RegularExpression::Pattern.new("(a|()|\\3b|())*?").match("aaabbb").to_a.should == ["", nil, nil, nil]
    RegularExpression::Pattern.new("(a|\\2b|()|())*?").match("aaabbb").to_a.should == ["", nil, nil, nil]
    RegularExpression::Pattern.new("(a|\\3b|()|())*?").match("aaabbb").to_a.should == ["", nil, nil, nil]
    RegularExpression::Pattern.new("(a|()|())*?").match("aaa").to_a.should == ["", nil, nil, nil]
    RegularExpression::Pattern.new("^(()|a|())*?$").match("aaa").to_a.should == ["aaa", "a", "", nil]
  end
end
