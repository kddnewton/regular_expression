require_relative "../rubyspec_helper"

describe "Regexps with grouping" do
  it "support ()" do
    RegularExpression::Pattern.new("(a)").match("a").to_a.should == ["a", "a"]
  end

  it "allows groups to be nested" do
    md = RegularExpression::Pattern.new("(hay(st)a)ck").match('haystack')
    md.to_a.should == ['haystack','haysta', 'st']
  end

  it "raises a SyntaxError when parentheses aren't balanced" do
   -> { eval "/(hay(st)ack/" }.should raise_error(SyntaxError)
  end

  it "supports (?: ) (non-capturing group)" do
    RegularExpression::Pattern.new("(?:foo)(bar)").match("foobar").to_a.should == ["foobar", "bar"]
    # Parsing precedence
    RegularExpression::Pattern.new("(?:xdigit:)").match("xdigit:").to_a.should == ["xdigit:"]
  end

  it "group names cannot start with digits or minus" do
    -> { Regexp.new("(?<1a>a)") }.should raise_error(RegexpError)
    -> { Regexp.new("(?<-a>a)") }.should raise_error(RegexpError)
  end

  it "ignore capture groups in line comments" do
    /^
     (a) # there is a capture group on this line
     b   # there is no capture group on this line (not even here)
     $/x.match("ab").to_a.should == [ "ab", "a" ]
  end
end
