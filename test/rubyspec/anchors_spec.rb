require_relative "../rubyspec_helper"

describe "Regexps with anchors" do
  it "supports ^ (line start anchor)" do
    # Basic matching
    RegularExpression::Pattern.new("^foo").match("foo").to_a.should == ["foo"]
    RegularExpression::Pattern.new("^bar").match("foo\nbar").to_a.should == ["bar"]
    # Basic non-matching
    RegularExpression::Pattern.new("^foo").match(" foo").should be_nil
    RegularExpression::Pattern.new("foo^").match("foo\n\n\n").should be_nil

    # A bit advanced
    RegularExpression::Pattern.new("^^^foo").match("foo").to_a.should == ["foo"]
    (RegularExpression::Pattern.new("^[^f]") =~ "foo\n\n").should == "foo\n".size and RegularExpression.last_match.to_a.should == ["\n"]
    (RegularExpression::Pattern.new("($^)($^)") =~ "foo\n\n").should == "foo\n".size and RegularExpression.last_match.to_a.should == ["", "", ""]

    # Different start of line chars
    RegularExpression::Pattern.new("^bar").match("foo\rbar").should be_nil
    RegularExpression::Pattern.new("^bar").match("foo\0bar").should be_nil

    # Trivial
    RegularExpression::Pattern.new("^").match("foo").to_a.should == [""]

    # Grouping
    RegularExpression::Pattern.new("(^foo)").match("foo").to_a.should == ["foo", "foo"]
    RegularExpression::Pattern.new("(^)").match("foo").to_a.should == ["", ""]
    RegularExpression::Pattern.new("(foo\n^)(^bar)").match("foo\nbar").to_a.should == ["foo\nbar", "foo\n", "bar"]
  end

  it "does not match ^ after trailing \\n" do
    RegularExpression::Pattern.new("^(?!\\A)").match("foo\n").should be_nil # There is no (empty) line after a trailing \n
  end

  it "supports $ (line end anchor)" do
    # Basic  matching
    RegularExpression::Pattern.new("foo$").match("foo").to_a.should == ["foo"]
    RegularExpression::Pattern.new("foo$").match("foo\nbar").to_a.should == ["foo"]
    # Basic non-matching
    RegularExpression::Pattern.new("foo$").match("foo ").should be_nil
    RegularExpression::Pattern.new("$foo").match("\n\n\nfoo").should be_nil

    # A bit advanced
    RegularExpression::Pattern.new("foo$$$").match("foo").to_a.should == ["foo"]
    (RegularExpression::Pattern.new("[^o]$") =~ "foo\n\n").should == ("foo\n".size - 1) and RegularExpression.last_match.to_a.should == ["\n"]

    # Different end of line chars
    RegularExpression::Pattern.new("foo$").match("foo\r\nbar").should be_nil
    RegularExpression::Pattern.new("foo$").match("foo\0bar").should be_nil

    # Trivial
    (RegularExpression::Pattern.new("$") =~ "foo").should == "foo".size and RegularExpression.last_match.to_a.should == [""]

    # Grouping
    RegularExpression::Pattern.new("(foo$)").match("foo").to_a.should == ["foo", "foo"]
    (RegularExpression::Pattern.new("($)") =~ "foo").should == "foo".size and RegularExpression.last_match.to_a.should == ["", ""]
    RegularExpression::Pattern.new("(foo$)($\nbar)").match("foo\nbar").to_a.should == ["foo\nbar", "foo", "\nbar"]
  end

  it "supports \\A (string start anchor)" do
    # Basic matching
    RegularExpression::Pattern.new("\\Afoo").match("foo").to_a.should == ["foo"]
    # Basic non-matching
    RegularExpression::Pattern.new("\\Abar").match("foo\nbar").should be_nil
    RegularExpression::Pattern.new("\\Afoo").match(" foo").should be_nil

    # A bit advanced
    RegularExpression::Pattern.new("\\A\\A\\Afoo").match("foo").to_a.should == ["foo"]
    RegularExpression::Pattern.new("(\\A\\Z)(\\A\\Z)").match("").to_a.should == ["", "", ""]

    # Different start of line chars
    RegularExpression::Pattern.new("\\Abar").match("foo\0bar").should be_nil

    # Grouping
    RegularExpression::Pattern.new("(\\Afoo)").match("foo").to_a.should == ["foo", "foo"]
    RegularExpression::Pattern.new("(\\A)").match("foo").to_a.should == ["", ""]
  end

  it "supports \\Z (string end anchor, including before trailing \\n)" do
    # Basic matching
    RegularExpression::Pattern.new("foo\\Z").match("foo").to_a.should == ["foo"]
    RegularExpression::Pattern.new("foo\\Z").match("foo\n").to_a.should == ["foo"]
    # Basic non-matching
    RegularExpression::Pattern.new("foo\\Z").match("foo\nbar").should be_nil
    RegularExpression::Pattern.new("foo\\Z").match("foo ").should be_nil

    # A bit advanced
    RegularExpression::Pattern.new("foo\\Z\\Z\\Z").match("foo\n").to_a.should == ["foo"]
    (RegularExpression::Pattern.new("($\\Z)($\\Z)") =~ "foo\n").should == "foo".size and RegularExpression.last_match.to_a.should == ["", "", ""]
    (RegularExpression::Pattern.new("(\\z\\Z)(\\z\\Z)") =~ "foo\n").should == "foo\n".size and RegularExpression.last_match.to_a.should == ["", "", ""]

    # Different end of line chars
    RegularExpression::Pattern.new("foo\\Z").match("foo\0bar").should be_nil
    RegularExpression::Pattern.new("foo\\Z").match("foo\r\n").should be_nil

    # Grouping
    RegularExpression::Pattern.new("(foo\\Z)").match("foo").to_a.should == ["foo", "foo"]
    (RegularExpression::Pattern.new("(\\Z)") =~ "foo").should == "foo".size and RegularExpression.last_match.to_a.should == ["", ""]
  end

  it "supports \\z (string end anchor)" do
    # Basic matching
    RegularExpression::Pattern.new("foo\\z").match("foo").to_a.should == ["foo"]
    # Basic non-matching
    RegularExpression::Pattern.new("foo\\z").match("foo\nbar").should be_nil
    RegularExpression::Pattern.new("foo\\z").match("foo\n").should be_nil
    RegularExpression::Pattern.new("foo\\z").match("foo ").should be_nil

    # A bit advanced
    RegularExpression::Pattern.new("foo\\z\\z\\z").match("foo").to_a.should == ["foo"]
    (RegularExpression::Pattern.new("($\\z)($\\z)") =~ "foo").should == "foo".size and RegularExpression.last_match.to_a.should == ["", "", ""]

    # Different end of line chars
    RegularExpression::Pattern.new("foo\\z").match("foo\0bar").should be_nil
    RegularExpression::Pattern.new("foo\\z").match("foo\r\nbar").should be_nil

    # Grouping
    RegularExpression::Pattern.new("(foo\\z)").match("foo").to_a.should == ["foo", "foo"]
    (RegularExpression::Pattern.new("(\\z)") =~ "foo").should == "foo".size and RegularExpression.last_match.to_a.should == ["", ""]
  end

  it "supports \\b (word boundary)" do
    # Basic matching
    RegularExpression::Pattern.new("foo\\b").match("foo").to_a.should == ["foo"]
    RegularExpression::Pattern.new("foo\\b").match("foo\n").to_a.should == ["foo"]
    LanguageSpecs.white_spaces.scan(RegularExpression::Pattern.new(".")).each do |c|
    RegularExpression::Pattern.new("foo\\b").match("foo" + c).to_a.should == ["foo"]
    end
    LanguageSpecs.non_alphanum_non_space.scan(RegularExpression::Pattern.new(".")).each do |c|
    RegularExpression::Pattern.new("foo\\b").match("foo" + c).to_a.should == ["foo"]
    end
    RegularExpression::Pattern.new("foo\\b").match("foo\0").to_a.should == ["foo"]
    # Basic non-matching
    RegularExpression::Pattern.new("foo\\b").match("foobar").should be_nil
    RegularExpression::Pattern.new("foo\\b").match("foo123").should be_nil
    RegularExpression::Pattern.new("foo\\b").match("foo_").should be_nil
  end

  it "supports \\B (non-word-boundary)" do
    # Basic matching
    RegularExpression::Pattern.new("foo\\B").match("foobar").to_a.should == ["foo"]
    RegularExpression::Pattern.new("foo\\B").match("foo123").to_a.should == ["foo"]
    RegularExpression::Pattern.new("foo\\B").match("foo_").to_a.should == ["foo"]
    # Basic non-matching
    RegularExpression::Pattern.new("foo\\B").match("foo").should be_nil
    RegularExpression::Pattern.new("foo\\B").match("foo\n").should be_nil
    LanguageSpecs.white_spaces.scan(RegularExpression::Pattern.new(".")).each do |c|
    RegularExpression::Pattern.new("foo\\B").match("foo" + c).should be_nil
    end
    LanguageSpecs.non_alphanum_non_space.scan(RegularExpression::Pattern.new(".")).each do |c|
    RegularExpression::Pattern.new("foo\\B").match("foo" + c).should be_nil
    end
    RegularExpression::Pattern.new("foo\\B").match("foo\0").should be_nil
  end

  it "supports (?= ) (positive lookahead)" do
    RegularExpression::Pattern.new("foo.(?=bar)").match("foo1 foo2bar").to_a.should == ["foo2"]
  end

  it "supports (?! ) (negative lookahead)" do
    RegularExpression::Pattern.new("foo.(?!bar)").match("foo1bar foo2").to_a.should == ["foo2"]
  end

  it "supports (?!<) (negative lookbehind)" do
    RegularExpression::Pattern.new("(?<!foo)bar.").match("foobar1 bar2").to_a.should == ["bar2"]
  end

  it "supports (?<=) (positive lookbehind)" do
    RegularExpression::Pattern.new("(?<=foo)bar.").match("bar1 foobar2").to_a.should == ["bar2"]
  end

  it "supports (?<=\\b) (positive lookbehind with word boundary)" do
    RegularExpression::Pattern.new("(?<=\\bfoo)bar.").match("1foobar1 foobar2").to_a.should == ["bar2"]
  end

  it "supports (?!<\\b) (negative lookbehind with word boundary)" do
    RegularExpression::Pattern.new("(?<!\\bfoo)bar.").match("foobar1 1foobar2").to_a.should == ["bar2"]
  end
end
