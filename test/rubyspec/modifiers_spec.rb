require_relative "../rubyspec_helper"

describe "Regexps with modifiers" do
  it "supports /i (case-insensitive)" do
    RegularExpression::Pattern.new("foo/", "i").match("FOO").to_a.should == ["FOO"]
  end

  it "supports /m (multiline)" do
    RegularExpression::Pattern.new("foo.bar/", "m").match("foo\nbar").to_a.should == ["foo\nbar"]
    RegularExpression::Pattern.new("foo.bar").match("foo\nbar").should be_nil
  end

  it "supports /x (extended syntax)" do
    RegularExpression::Pattern.new("\\d +/", "x").match("abc123").to_a.should == ["123"] # Quantifiers can be separated from the expression they apply to
  end

  it "supports /o (once)" do
    2.times do |i|
      RegularExpression::Pattern.new("#{i}/", "o").should == RegularExpression::Pattern.new("0")
    end
  end

  it "invokes substitutions for /o only once" do
    ScratchPad.record []
    o = Object.new
    def o.to_s
      ScratchPad << :to_s
      "class_with_to_s"
    end
    eval "2.times { /#{o}/o }"
    ScratchPad.recorded.should == [:to_s]
  end

  it "supports modifier combinations" do
    RegularExpression::Pattern.new("foo/imo", "imox").match("foo").to_a.should == ["foo"]
    RegularExpression::Pattern.new("foo/imoximo", "imoximox").match("foo").to_a.should == ["foo"]

    -> { eval('/foo/a') }.should raise_error(SyntaxError)
  end

  it "supports (?~) (absent operator)" do
    Regexp.new("(?~foo)").match("hello").to_a.should == ["hello"]
    "foo".scan(Regexp.new("(?~foo)")).should == ["fo","o",""]
  end

  it "supports (?imx-imx) (inline modifiers)" do
    RegularExpression::Pattern.new("(?i)foo").match("FOO").to_a.should == ["FOO"]
    RegularExpression::Pattern.new("foo(?i)").match("FOO").should be_nil
    # Interaction with /i
    RegularExpression::Pattern.new("(?-i)foo/", "i").match("FOO").should be_nil
    RegularExpression::Pattern.new("foo(?-i)/", "i").match("FOO").to_a.should == ["FOO"]
    # Multiple uses
    RegularExpression::Pattern.new("foo (?i)bar (?-i)baz").match("foo BAR baz").to_a.should == ["foo BAR baz"]
    RegularExpression::Pattern.new("foo (?i)bar (?-i)baz").match("foo BAR BAZ").should be_nil

    RegularExpression::Pattern.new("(?m).").match("\n").to_a.should == ["\n"]
    RegularExpression::Pattern.new(".(?m)").match("\n").should be_nil
    # Interaction with /m
    RegularExpression::Pattern.new("(?-m)./", "m").match("\n").should be_nil
    RegularExpression::Pattern.new(".(?-m)/", "m").match("\n").to_a.should == ["\n"]
    # Multiple uses
    RegularExpression::Pattern.new(". (?m). (?-m).").match(". \n .").to_a.should == [". \n ."]
    RegularExpression::Pattern.new(". (?m). (?-m).").match(". \n \n").should be_nil

    RegularExpression::Pattern.new("(?x) foo ").match("foo").to_a.should == ["foo"]
    RegularExpression::Pattern.new(" foo (?x)").match("foo").should be_nil
    # Interaction with /x
    RegularExpression::Pattern.new("(?-x) foo /", "x").match("foo").should be_nil
    RegularExpression::Pattern.new(" foo (?-x)/", "x").match("foo").to_a.should == ["foo"]
    # Multiple uses
    RegularExpression::Pattern.new("( foo )(?x)( bar )(?-x)( baz )").match(" foo bar baz ").to_a.should == [" foo bar baz ", " foo ", "bar", " baz "]
    RegularExpression::Pattern.new("( foo )(?x)( bar )(?-x)( baz )").match(" foo barbaz").should be_nil

    # Parsing
    RegularExpression::Pattern.new("(?i-i)foo").match("FOO").should be_nil
    RegularExpression::Pattern.new("(?ii)foo").match("FOO").to_a.should == ["FOO"]
    RegularExpression::Pattern.new("(?-)foo").match("foo").to_a.should == ["foo"]
    -> { eval('/(?o)/') }.should raise_error(SyntaxError)
  end

  it "supports (?imx-imx:expr) (scoped inline modifiers)" do
    RegularExpression::Pattern.new("foo (?i:bar) baz").match("foo BAR baz").to_a.should == ["foo BAR baz"]
    RegularExpression::Pattern.new("foo (?i:bar) baz").match("foo BAR BAZ").should be_nil
    RegularExpression::Pattern.new("foo (?-i:bar) baz/", "i").match("foo BAR BAZ").should be_nil

    RegularExpression::Pattern.new(". (?m:.) .").match(". \n .").to_a.should == [". \n ."]
    RegularExpression::Pattern.new(". (?m:.) .").match(". \n \n").should be_nil
    RegularExpression::Pattern.new(". (?-m:.) ./", "m").match("\n \n \n").should be_nil

    RegularExpression::Pattern.new("( foo )(?x: bar )( baz )").match(" foo bar baz ").to_a.should == [" foo bar baz ", " foo ", " baz "]
    RegularExpression::Pattern.new("( foo )(?x: bar )( baz )").match(" foo barbaz").should be_nil
    RegularExpression::Pattern.new("( foo )(?-x: bar )( baz )/", "x").match("foo bar baz").to_a.should == ["foo bar baz", "foo", "baz"]

    # Parsing
    RegularExpression::Pattern.new("(?i-i:foo)").match("FOO").should be_nil
    RegularExpression::Pattern.new("(?ii:foo)").match("FOO").to_a.should == ["FOO"]
    RegularExpression::Pattern.new("(?-:)foo").match("foo").to_a.should == ["foo"]
    -> { eval('/(?o:)/') }.should raise_error(SyntaxError)
  end

  it "supports . with /m" do
    # Basic matching
    RegularExpression::Pattern.new("./", "m").match("\n").to_a.should == ["\n"]
  end

  it "supports ASCII/Unicode modifiers" do
    eval('/(?a)[[:alpha:]]+/').match("a\u3042").to_a.should == ["a"]
    eval('/(?d)[[:alpha:]]+/').match("a\u3042").to_a.should == ["a\u3042"]
    eval('/(?u)[[:alpha:]]+/').match("a\u3042").to_a.should == ["a\u3042"]
    eval('/(?a)\w+/').match("a\u3042").to_a.should == ["a"]
    eval('/(?d)\w+/').match("a\u3042").to_a.should == ["a"]
    eval('/(?u)\w+/').match("a\u3042").to_a.should == ["a\u3042"]
  end
end
