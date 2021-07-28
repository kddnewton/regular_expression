require_relative "../rubyspec_helper"

describe "Regexps with interpolation" do

  it "allows interpolation of strings" do
    str = "foo|bar"
    RegularExpression::Pattern.new("#{str}").should == RegularExpression::Pattern.new("foo|bar")
  end

  it "allows interpolation of literal regexps" do
    re = RegularExpression::Pattern.new("foo|bar")
    RegularExpression::Pattern.new("#{re}").should == RegularExpression::Pattern.new("(?-mix:foo|bar)")
  end

  it "allows interpolation of any object that responds to to_s" do
    o = Object.new
    def o.to_s
      "object_with_to_s"
    end
    RegularExpression::Pattern.new("#{o}").should == RegularExpression::Pattern.new("object_with_to_s")
  end

  it "allows interpolation which mixes modifiers" do
    re = RegularExpression::Pattern.new("foo/", "i")
    RegularExpression::Pattern.new("#{re} bar/", "m").should == RegularExpression::Pattern.new("(?i-mx:foo) bar/", "m")
  end

  it "allows interpolation to interact with other Regexp constructs" do
    str = "foo)|(bar"
    RegularExpression::Pattern.new("(#{str})").should == RegularExpression::Pattern.new("(foo)|(bar)")

    str = "a"
    RegularExpression::Pattern.new("[#{str}-z]").should == RegularExpression::Pattern.new("[a-z]")
  end

  it "gives precedence to escape sequences over substitution" do
    str = "J"
    RegularExpression::Pattern.new("\c#{str}").to_s.should include('{str}')
  end

  it "throws RegexpError for malformed interpolation" do
    s = ""
    -> { RegularExpression::Pattern.new("(#{s}") }.should raise_error(RegexpError)
    s = "("
    -> { RegularExpression::Pattern.new("#{s}") }.should raise_error(RegexpError)
  end

  it "allows interpolation in extended mode" do
    var = "#comment\n  foo  #comment\n  |  bar"
    (RegularExpression::Pattern.new("#{var}/", "x") =~ "foo").should == (RegularExpression::Pattern.new("foo|bar") =~ "foo")
  end

  it "allows escape sequences in interpolated regexps" do
    escape_seq = RegularExpression::Pattern.new("\"\x80\"}", "n")
    RegularExpression::Pattern.new("#{escape_seq}}", "n").should == RegularExpression::Pattern.new("(?-mix:\"\x80\")/", "n")
  end
end
