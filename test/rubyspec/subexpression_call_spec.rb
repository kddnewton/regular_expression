require_relative "../rubyspec_helper"

describe "Regexps with subexpression calls" do
  it "allows numeric subexpression calls" do
    RegularExpression::Pattern.new("(a)\\g<1>").match("aa").to_a.should == [ "aa", "a" ]
  end

  it "treats subexpression calls as distinct from simple back-references" do
    # Back-references only match a string which is equal to the original captured string.
    RegularExpression::Pattern.new("(?<three_digits>[0-9]{3})-\\k<three_digits>").match("123-123")[0].should == "123-123"
    RegularExpression::Pattern.new("(?<three_digits>[0-9]{3})-\\k<three_digits>").match("123-456").should == nil
    # However, subexpression calls reuse the previous expression and can match a different
    # string.
    RegularExpression::Pattern.new("(?<three_digits>[0-9]{3})-\\g<three_digits>").match("123-456")[0].should == "123-456"
  end

  it "allows recursive subexpression calls" do
    # This pattern matches well-nested parenthesized expression.
    parens = RegularExpression::Pattern.new("^ (?<parens>  (?: \\( \\g<parens> \\) | [^()] )*  ) $/", "x")
    parens.match("((a)(b))c(d)")[0].should == "((a)(b))c(d)"
    parens.match("((a)(b)c(d)").should == nil
  end

  it "allows access to back-references from the current level" do
    # Using \\k<first_char-0> accesses the last value captured in first_char
    # on the current stack level.
    mirror = RegularExpression::Pattern.new("^ (?<mirror> (?: (?<first_char>.) \\g<mirror> \\k<first_char-0> )? ) $/", "x")
    mirror.match("abccba")[0].should == "abccba"
    mirror.match("abccbd").should == nil

    # OTOH, using \\k<first_char> accesses the last value captured in first_char,
    # regardless of the stack level. Therefore, it can't be used to implement
    # the mirror language.
    broken_mirror = RegularExpression::Pattern.new("^ (?<mirror> (?: (?<first_char>.) \\g<mirror> \\k<first_char> )? ) $/", "x")
    broken_mirror.match("abccba").should == nil
    # This matches because the 'c' is captured in first_char and that value is
    # then used for all subsequent back-references, regardless of nesting.
    broken_mirror.match("abcccc")[0].should == "abcccc"
  end

  it "allows + and - in group names and referential constructs that don't use levels, i.e. subexpression calls" do
    RegularExpression::Pattern.new("(?<a+>a)\\g<a+>").match("aa").to_a.should == [ "aa", "a" ]
    RegularExpression::Pattern.new("(?<a+b>a)\\g<a+b>").match("aa").to_a.should == [ "aa", "a" ]
    RegularExpression::Pattern.new("(?<a+1>a)\\g<a+1>").match("aa").to_a.should == [ "aa", "a" ]
    RegularExpression::Pattern.new("(?<a->a)\\g<a->").match("aa").to_a.should == [ "aa", "a" ]
    RegularExpression::Pattern.new("(?<a-b>a)\\g<a-b>").match("aa").to_a.should == [ "aa", "a" ]
    RegularExpression::Pattern.new("(?<a-1>a)\\g<a-1>").match("aa").to_a.should == [ "aa", "a" ]
  end
end
