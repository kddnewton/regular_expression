# coding: utf-8
require_relative "../rubyspec_helper"

describe "Regexp with character classes" do
  it "supports \\w (word character)" do
    RegularExpression::Pattern.new("\\w").match("a").to_a.should == ["a"]
    RegularExpression::Pattern.new("\\w").match("1").to_a.should == ["1"]
    RegularExpression::Pattern.new("\\w").match("_").to_a.should == ["_"]

    # Non-matches
    RegularExpression::Pattern.new("\\w").match(LanguageSpecs.white_spaces).should be_nil
    RegularExpression::Pattern.new("\\w").match(LanguageSpecs.non_alphanum_non_space).should be_nil
    RegularExpression::Pattern.new("\\w").match("\0").should be_nil
  end

  it "supports \\W (non-word character)" do
    RegularExpression::Pattern.new("\\W+").match(LanguageSpecs.white_spaces).to_a.should == [LanguageSpecs.white_spaces]
    RegularExpression::Pattern.new("\\W+").match(LanguageSpecs.non_alphanum_non_space).to_a.should == [LanguageSpecs.non_alphanum_non_space]
    RegularExpression::Pattern.new("\\W").match("\0").to_a.should == ["\0"]

    # Non-matches
    RegularExpression::Pattern.new("\\W").match("a").should be_nil
    RegularExpression::Pattern.new("\\W").match("1").should be_nil
    RegularExpression::Pattern.new("\\W").match("_").should be_nil
  end

  it "supports \\s (space character)" do
    RegularExpression::Pattern.new("\\s+").match(LanguageSpecs.white_spaces).to_a.should == [LanguageSpecs.white_spaces]

    # Non-matches
    RegularExpression::Pattern.new("\\s").match("a").should be_nil
    RegularExpression::Pattern.new("\\s").match("1").should be_nil
    RegularExpression::Pattern.new("\\s").match(LanguageSpecs.non_alphanum_non_space).should be_nil
    RegularExpression::Pattern.new("\\s").match("\0").should be_nil
  end

  it "supports \\S (non-space character)" do
    RegularExpression::Pattern.new("\\S").match("a").to_a.should == ["a"]
    RegularExpression::Pattern.new("\\S").match("1").to_a.should == ["1"]
    RegularExpression::Pattern.new("\\S+").match(LanguageSpecs.non_alphanum_non_space).to_a.should == [LanguageSpecs.non_alphanum_non_space]
    RegularExpression::Pattern.new("\\S").match("\0").to_a.should == ["\0"]

    # Non-matches
    RegularExpression::Pattern.new("\\S").match(LanguageSpecs.white_spaces).should be_nil
  end

  it "supports \\d (numeric digit)" do
    RegularExpression::Pattern.new("\\d").match("1").to_a.should == ["1"]

    # Non-matches
    RegularExpression::Pattern.new("\\d").match("a").should be_nil
    RegularExpression::Pattern.new("\\d").match(LanguageSpecs.white_spaces).should be_nil
    RegularExpression::Pattern.new("\\d").match(LanguageSpecs.non_alphanum_non_space).should be_nil
    RegularExpression::Pattern.new("\\d").match("\0").should be_nil
  end

  it "supports \\D (non-digit)" do
    RegularExpression::Pattern.new("\\D").match("a").to_a.should == ["a"]
    RegularExpression::Pattern.new("\\D+").match(LanguageSpecs.white_spaces).to_a.should == [LanguageSpecs.white_spaces]
    RegularExpression::Pattern.new("\\D+").match(LanguageSpecs.non_alphanum_non_space).to_a.should == [LanguageSpecs.non_alphanum_non_space]
    RegularExpression::Pattern.new("\\D").match("\0").to_a.should == ["\0"]

    # Non-matches
    RegularExpression::Pattern.new("\\D").match("1").should be_nil
  end

  it "supports [] (character class)" do
    RegularExpression::Pattern.new("[a-z]+").match("fooBAR").to_a.should == ["foo"]
    RegularExpression::Pattern.new("[\\b]").match("\b").to_a.should == ["\b"] # \b inside character class is backspace
  end

  it "supports [[:alpha:][:digit:][:etc:]] (predefined character classes)" do
    RegularExpression::Pattern.new("[[:alnum:]]+").match("a1").to_a.should == ["a1"]
    RegularExpression::Pattern.new("[[:alpha:]]+").match("Aa1").to_a.should == ["Aa"]
    RegularExpression::Pattern.new("[[:blank:]]+").match(LanguageSpecs.white_spaces).to_a.should == [LanguageSpecs.blanks]
    # /[[:cntrl:]]/.match("").to_a.should == [""] # TODO: what should this match?
    RegularExpression::Pattern.new("[[:digit:]]").match("1").to_a.should == ["1"]
    # /[[:graph:]]/.match("").to_a.should == [""] # TODO: what should this match?
    RegularExpression::Pattern.new("[[:lower:]]+").match("Aa1").to_a.should == ["a"]
    RegularExpression::Pattern.new("[[:print:]]+").match(LanguageSpecs.white_spaces).to_a.should == [" "]     # include all of multibyte encoded characters
    RegularExpression::Pattern.new("[[:punct:]]+").match(LanguageSpecs.punctuations).to_a.should == [LanguageSpecs.punctuations]
    RegularExpression::Pattern.new("[[:space:]]+").match(LanguageSpecs.white_spaces).to_a.should == [LanguageSpecs.white_spaces]
    RegularExpression::Pattern.new("[[:upper:]]+").match("123ABCabc").to_a.should == ["ABC"]
    RegularExpression::Pattern.new("[[:xdigit:]]+").match("xyz0123456789ABCDEFabcdefXYZ").to_a.should == ["0123456789ABCDEFabcdef"]

    # Parsing
    RegularExpression::Pattern.new("[[:lower:][:digit:]A-C]+").match("a1ABCDEF").to_a.should == ["a1ABC"] # can be composed with other constructs in the character class
    RegularExpression::Pattern.new("[^[:lower:]A-C]+").match("abcABCDEF123def").to_a.should == ["DEF123"] # negated character class
    RegularExpression::Pattern.new("[:alnum:]+").match("a:l:n:u:m").to_a.should == ["a:l:n:u:m"] # should behave like regular character class composed of the individual letters
    RegularExpression::Pattern.new("[\\[:alnum:]+").match("[:a:l:n:u:m").to_a.should == ["[:a:l:n:u:m"] # should behave like regular character class composed of the individual letters
    -> { eval('/[[:alpha:]-[:digit:]]/') }.should raise_error(SyntaxError) # can't use character class as a start value of range
  end

  it "matches ASCII characters with [[:ascii:]]" do
    "\x00".match(RegularExpression::Pattern.new("[[:ascii:]]")).to_a.should == ["\x00"]
    "\x7F".match(RegularExpression::Pattern.new("[[:ascii:]]")).to_a.should == ["\x7F"]
  end

  not_supported_on :opal do
    it "doesn't match non-ASCII characters with [[:ascii:]]" do
      RegularExpression::Pattern.new("[[:ascii:]]").match("\u{80}").should be_nil
      RegularExpression::Pattern.new("[[:ascii:]]").match("\u{9898}").should be_nil
    end
  end

  it "matches Unicode letter characters with [[:alnum:]]" do
    "à".match(RegularExpression::Pattern.new("[[:alnum:]]")).to_a.should == ["à"]
  end

  it "matches Unicode digits with [[:alnum:]]" do
    "\u{0660}".match(RegularExpression::Pattern.new("[[:alnum:]]")).to_a.should == ["\u{0660}"]
  end

  it "doesn't matches Unicode marks with [[:alnum:]]" do
    "\u{36F}".match(RegularExpression::Pattern.new("[[:alnum:]]")).should be_nil
  end

  it "doesn't match Unicode control characters with [[:alnum:]]" do
    "\u{16}".match(RegularExpression::Pattern.new("[[:alnum:]]")).to_a.should == []
  end

  it "doesn't match Unicode punctuation characters with [[:alnum:]]" do
    "\u{3F}".match(RegularExpression::Pattern.new("[[:alnum:]]")).to_a.should == []
  end

  it "matches Unicode letter characters with [[:alpha:]]" do
    "à".match(RegularExpression::Pattern.new("[[:alpha:]]")).to_a.should == ["à"]
  end

  it "doesn't match Unicode digits with [[:alpha:]]" do
    "\u{0660}".match(RegularExpression::Pattern.new("[[:alpha:]]")).to_a.should == []
  end

  it "doesn't matches Unicode marks with [[:alpha:]]" do
    "\u{36F}".match(RegularExpression::Pattern.new("[[:alpha:]]")).should be_nil
  end

  it "doesn't match Unicode control characters with [[:alpha:]]" do
    "\u{16}".match(RegularExpression::Pattern.new("[[:alpha:]]")).to_a.should == []
  end

  it "doesn't match Unicode punctuation characters with [[:alpha:]]" do
    "\u{3F}".match(RegularExpression::Pattern.new("[[:alpha:]]")).to_a.should == []
  end

  it "matches Unicode space characters with [[:blank:]]" do
    "\u{1680}".match(RegularExpression::Pattern.new("[[:blank:]]")).to_a.should == ["\u{1680}"]
  end

  it "doesn't match Unicode control characters with [[:blank:]]" do
    "\u{16}".match(RegularExpression::Pattern.new("[[:blank:]]")).should be_nil
  end

  it "doesn't match Unicode punctuation characters with [[:blank:]]" do
    "\u{3F}".match(RegularExpression::Pattern.new("[[:blank:]]")).should be_nil
  end

  it "doesn't match Unicode letter characters with [[:blank:]]" do
    "à".match(RegularExpression::Pattern.new("[[:blank:]]")).should be_nil
  end

  it "doesn't match Unicode digits with [[:blank:]]" do
    "\u{0660}".match(RegularExpression::Pattern.new("[[:blank:]]")).should be_nil
  end

  it "doesn't match Unicode marks with [[:blank:]]" do
    "\u{36F}".match(RegularExpression::Pattern.new("[[:blank:]]")).should be_nil
  end

  it "doesn't Unicode letter characters with [[:cntrl:]]" do
    "à".match(RegularExpression::Pattern.new("[[:cntrl:]]")).should be_nil
  end

  it "doesn't match Unicode digits with [[:cntrl:]]" do
    "\u{0660}".match(RegularExpression::Pattern.new("[[:cntrl:]]")).should be_nil
  end

  it "doesn't match Unicode marks with [[:cntrl:]]" do
    "\u{36F}".match(RegularExpression::Pattern.new("[[:cntrl:]]")).should be_nil
  end

  it "doesn't match Unicode punctuation characters with [[:cntrl:]]" do
    "\u{3F}".match(RegularExpression::Pattern.new("[[:cntrl:]]")).should be_nil
  end

  it "matches Unicode control characters with [[:cntrl:]]" do
    "\u{16}".match(RegularExpression::Pattern.new("[[:cntrl:]]")).to_a.should == ["\u{16}"]
  end

  it "doesn't match Unicode format characters with [[:cntrl:]]" do
    "\u{2060}".match(RegularExpression::Pattern.new("[[:cntrl:]]")).should be_nil
  end

  it "doesn't match Unicode private-use characters with [[:cntrl:]]" do
    "\u{E001}".match(RegularExpression::Pattern.new("[[:cntrl:]]")).should be_nil
  end

  it "doesn't match Unicode letter characters with [[:digit:]]" do
    "à".match(RegularExpression::Pattern.new("[[:digit:]]")).should be_nil
  end

  it "matches Unicode digits with [[:digit:]]" do
    "\u{0660}".match(RegularExpression::Pattern.new("[[:digit:]]")).to_a.should == ["\u{0660}"]
    "\u{FF12}".match(RegularExpression::Pattern.new("[[:digit:]]")).to_a.should == ["\u{FF12}"]
  end

  it "doesn't match Unicode marks with [[:digit:]]" do
    "\u{36F}".match(RegularExpression::Pattern.new("[[:digit:]]")).should be_nil
  end

  it "doesn't match Unicode punctuation characters with [[:digit:]]" do
    "\u{3F}".match(RegularExpression::Pattern.new("[[:digit:]]")).should be_nil
  end

  it "doesn't match Unicode control characters with [[:digit:]]" do
    "\u{16}".match(RegularExpression::Pattern.new("[[:digit:]]")).should be_nil
  end

  it "doesn't match Unicode format characters with [[:digit:]]" do
    "\u{2060}".match(RegularExpression::Pattern.new("[[:digit:]]")).should be_nil
  end

  it "doesn't match Unicode private-use characters with [[:digit:]]" do
    "\u{E001}".match(RegularExpression::Pattern.new("[[:digit:]]")).should be_nil
  end

  it "matches Unicode letter characters with [[:graph:]]" do
      "à".match(RegularExpression::Pattern.new("[[:graph:]]")).to_a.should == ["à"]
  end

  it "matches Unicode digits with [[:graph:]]" do
    "\u{0660}".match(RegularExpression::Pattern.new("[[:graph:]]")).to_a.should == ["\u{0660}"]
    "\u{FF12}".match(RegularExpression::Pattern.new("[[:graph:]]")).to_a.should == ["\u{FF12}"]
  end

  it "matches Unicode marks with [[:graph:]]" do
    "\u{36F}".match(RegularExpression::Pattern.new("[[:graph:]]")).to_a.should ==["\u{36F}"]
  end

  it "matches Unicode punctuation characters with [[:graph:]]" do
    "\u{3F}".match(RegularExpression::Pattern.new("[[:graph:]]")).to_a.should == ["\u{3F}"]
  end

  it "doesn't match Unicode control characters with [[:graph:]]" do
    "\u{16}".match(RegularExpression::Pattern.new("[[:graph:]]")).should be_nil
  end

  it "match Unicode format characters with [[:graph:]]" do
    "\u{2060}".match(RegularExpression::Pattern.new("[[:graph:]]")).to_a.should == ["\u2060"]
  end

  it "match Unicode private-use characters with [[:graph:]]" do
    "\u{E001}".match(RegularExpression::Pattern.new("[[:graph:]]")).to_a.should == ["\u{E001}"]
  end

  it "matches Unicode lowercase letter characters with [[:lower:]]" do
    "\u{FF41}".match(RegularExpression::Pattern.new("[[:lower:]]")).to_a.should == ["\u{FF41}"]
    "\u{1D484}".match(RegularExpression::Pattern.new("[[:lower:]]")).to_a.should == ["\u{1D484}"]
    "\u{E8}".match(RegularExpression::Pattern.new("[[:lower:]]")).to_a.should == ["\u{E8}"]
  end

  it "doesn't match Unicode uppercase letter characters with [[:lower:]]" do
    "\u{100}".match(RegularExpression::Pattern.new("[[:lower:]]")).should be_nil
    "\u{130}".match(RegularExpression::Pattern.new("[[:lower:]]")).should be_nil
    "\u{405}".match(RegularExpression::Pattern.new("[[:lower:]]")).should be_nil
  end

  it "doesn't match Unicode title-case characters with [[:lower:]]" do
    "\u{1F88}".match(RegularExpression::Pattern.new("[[:lower:]]")).should be_nil
    "\u{1FAD}".match(RegularExpression::Pattern.new("[[:lower:]]")).should be_nil
    "\u{01C5}".match(RegularExpression::Pattern.new("[[:lower:]]")).should be_nil
  end

  it "doesn't match Unicode digits with [[:lower:]]" do
    "\u{0660}".match(RegularExpression::Pattern.new("[[:lower:]]")).should be_nil
    "\u{FF12}".match(RegularExpression::Pattern.new("[[:lower:]]")).should be_nil
  end

  it "doesn't match Unicode marks with [[:lower:]]" do
    "\u{36F}".match(RegularExpression::Pattern.new("[[:lower:]]")).should be_nil
  end

  it "doesn't match Unicode punctuation characters with [[:lower:]]" do
    "\u{3F}".match(RegularExpression::Pattern.new("[[:lower:]]")).should be_nil
  end

  it "doesn't match Unicode control characters with [[:lower:]]" do
    "\u{16}".match(RegularExpression::Pattern.new("[[:lower:]]")).should be_nil
  end

  it "doesn't match Unicode format characters with [[:lower:]]" do
    "\u{2060}".match(RegularExpression::Pattern.new("[[:lower:]]")).should be_nil
  end

  it "doesn't match Unicode private-use characters with [[:lower:]]" do
    "\u{E001}".match(RegularExpression::Pattern.new("[[:lower:]]")).should be_nil
  end

  it "matches Unicode lowercase letter characters with [[:print:]]" do
    "\u{FF41}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{FF41}"]
    "\u{1D484}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{1D484}"]
    "\u{E8}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{E8}"]
  end

  it "matches Unicode uppercase letter characters with [[:print:]]" do
    "\u{100}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{100}"]
    "\u{130}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{130}"]
    "\u{405}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{405}"]
  end

  it "matches Unicode title-case characters with [[:print:]]" do
    "\u{1F88}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{1F88}"]
    "\u{1FAD}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{1FAD}"]
    "\u{01C5}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{01C5}"]
  end

  it "matches Unicode digits with [[:print:]]" do
    "\u{0660}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{0660}"]
    "\u{FF12}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{FF12}"]
  end

  it "matches Unicode marks with [[:print:]]" do
    "\u{36F}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{36F}"]
  end

  it "matches Unicode punctuation characters with [[:print:]]" do
    "\u{3F}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{3F}"]
  end

  it "doesn't match Unicode control characters with [[:print:]]" do
    "\u{16}".match(RegularExpression::Pattern.new("[[:print:]]")).should be_nil
  end

  it "match Unicode format characters with [[:print:]]" do
    "\u{2060}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{2060}"]
  end

  it "match Unicode private-use characters with [[:print:]]" do
    "\u{E001}".match(RegularExpression::Pattern.new("[[:print:]]")).to_a.should == ["\u{E001}"]
  end


  it "doesn't match Unicode lowercase letter characters with [[:punct:]]" do
    "\u{FF41}".match(RegularExpression::Pattern.new("[[:punct:]]")).should be_nil
    "\u{1D484}".match(RegularExpression::Pattern.new("[[:punct:]]")).should be_nil
    "\u{E8}".match(RegularExpression::Pattern.new("[[:punct:]]")).should be_nil
  end

  it "doesn't match Unicode uppercase letter characters with [[:punct:]]" do
    "\u{100}".match(RegularExpression::Pattern.new("[[:punct:]]")).should be_nil
    "\u{130}".match(RegularExpression::Pattern.new("[[:punct:]]")).should be_nil
    "\u{405}".match(RegularExpression::Pattern.new("[[:punct:]]")).should be_nil
  end

  it "doesn't match Unicode title-case characters with [[:punct:]]" do
    "\u{1F88}".match(RegularExpression::Pattern.new("[[:punct:]]")).should be_nil
    "\u{1FAD}".match(RegularExpression::Pattern.new("[[:punct:]]")).should be_nil
    "\u{01C5}".match(RegularExpression::Pattern.new("[[:punct:]]")).should be_nil
  end

  it "doesn't match Unicode digits with [[:punct:]]" do
    "\u{0660}".match(RegularExpression::Pattern.new("[[:punct:]]")).should be_nil
    "\u{FF12}".match(RegularExpression::Pattern.new("[[:punct:]]")).should be_nil
  end

  it "doesn't match Unicode marks with [[:punct:]]" do
    "\u{36F}".match(RegularExpression::Pattern.new("[[:punct:]]")).should be_nil
  end

  it "matches Unicode Pc characters with [[:punct:]]" do
    "\u{203F}".match(RegularExpression::Pattern.new("[[:punct:]]")).to_a.should == ["\u{203F}"]
  end

  it "matches Unicode Pd characters with [[:punct:]]" do
    "\u{2E17}".match(RegularExpression::Pattern.new("[[:punct:]]")).to_a.should == ["\u{2E17}"]
  end

  it "matches Unicode Ps characters with [[:punct:]]" do
    "\u{0F3A}".match(RegularExpression::Pattern.new("[[:punct:]]")).to_a.should == ["\u{0F3A}"]
  end

  it "matches Unicode Pe characters with [[:punct:]]" do
    "\u{2046}".match(RegularExpression::Pattern.new("[[:punct:]]")).to_a.should == ["\u{2046}"]
  end

  it "matches Unicode Pi characters with [[:punct:]]" do
    "\u{00AB}".match(RegularExpression::Pattern.new("[[:punct:]]")).to_a.should == ["\u{00AB}"]
  end

  it "matches Unicode Pf characters with [[:punct:]]" do
    "\u{201D}".match(RegularExpression::Pattern.new("[[:punct:]]")).to_a.should == ["\u{201D}"]
    "\u{00BB}".match(RegularExpression::Pattern.new("[[:punct:]]")).to_a.should == ["\u{00BB}"]
  end

  it "matches Unicode Po characters with [[:punct:]]" do
    "\u{00BF}".match(RegularExpression::Pattern.new("[[:punct:]]")).to_a.should == ["\u{00BF}"]
  end

  it "doesn't match Unicode format characters with [[:punct:]]" do
    "\u{2060}".match(RegularExpression::Pattern.new("[[:punct:]]")).should be_nil
  end

  it "doesn't match Unicode private-use characters with [[:punct:]]" do
    "\u{E001}".match(RegularExpression::Pattern.new("[[:punct:]]")).should be_nil
  end

  it "doesn't match Unicode lowercase letter characters with [[:space:]]" do
    "\u{FF41}".match(RegularExpression::Pattern.new("[[:space:]]")).should be_nil
    "\u{1D484}".match(RegularExpression::Pattern.new("[[:space:]]")).should be_nil
    "\u{E8}".match(RegularExpression::Pattern.new("[[:space:]]")).should be_nil
  end

  it "doesn't match Unicode uppercase letter characters with [[:space:]]" do
    "\u{100}".match(RegularExpression::Pattern.new("[[:space:]]")).should be_nil
    "\u{130}".match(RegularExpression::Pattern.new("[[:space:]]")).should be_nil
    "\u{405}".match(RegularExpression::Pattern.new("[[:space:]]")).should be_nil
  end

  it "doesn't match Unicode title-case characters with [[:space:]]" do
    "\u{1F88}".match(RegularExpression::Pattern.new("[[:space:]]")).should be_nil
    "\u{1FAD}".match(RegularExpression::Pattern.new("[[:space:]]")).should be_nil
    "\u{01C5}".match(RegularExpression::Pattern.new("[[:space:]]")).should be_nil
  end

  it "doesn't match Unicode digits with [[:space:]]" do
    "\u{0660}".match(RegularExpression::Pattern.new("[[:space:]]")).should be_nil
    "\u{FF12}".match(RegularExpression::Pattern.new("[[:space:]]")).should be_nil
  end

  it "doesn't match Unicode marks with [[:space:]]" do
    "\u{36F}".match(RegularExpression::Pattern.new("[[:space:]]")).should be_nil
  end

  it "matches Unicode Zs characters with [[:space:]]" do
    "\u{205F}".match(RegularExpression::Pattern.new("[[:space:]]")).to_a.should == ["\u{205F}"]
  end

  it "matches Unicode Zl characters with [[:space:]]" do
    "\u{2028}".match(RegularExpression::Pattern.new("[[:space:]]")).to_a.should == ["\u{2028}"]
  end

  it "matches Unicode Zp characters with [[:space:]]" do
    "\u{2029}".match(RegularExpression::Pattern.new("[[:space:]]")).to_a.should == ["\u{2029}"]
  end

  it "doesn't match Unicode format characters with [[:space:]]" do
    "\u{2060}".match(RegularExpression::Pattern.new("[[:space:]]")).should be_nil
  end

  it "doesn't match Unicode private-use characters with [[:space:]]" do
    "\u{E001}".match(RegularExpression::Pattern.new("[[:space:]]")).should be_nil
  end

  it "doesn't match Unicode lowercase characters with [[:upper:]]" do
    "\u{FF41}".match(RegularExpression::Pattern.new("[[:upper:]]")).should be_nil
    "\u{1D484}".match(RegularExpression::Pattern.new("[[:upper:]]")).should be_nil
    "\u{E8}".match(RegularExpression::Pattern.new("[[:upper:]]")).should be_nil
  end

  it "matches Unicode uppercase characters with [[:upper:]]" do
    "\u{100}".match(RegularExpression::Pattern.new("[[:upper:]]")).to_a.should == ["\u{100}"]
    "\u{130}".match(RegularExpression::Pattern.new("[[:upper:]]")).to_a.should == ["\u{130}"]
    "\u{405}".match(RegularExpression::Pattern.new("[[:upper:]]")).to_a.should == ["\u{405}"]
  end

  it "doesn't match Unicode title-case characters with [[:upper:]]" do
    "\u{1F88}".match(RegularExpression::Pattern.new("[[:upper:]]")).should be_nil
    "\u{1FAD}".match(RegularExpression::Pattern.new("[[:upper:]]")).should be_nil
    "\u{01C5}".match(RegularExpression::Pattern.new("[[:upper:]]")).should be_nil
  end

  it "doesn't match Unicode digits with [[:upper:]]" do
    "\u{0660}".match(RegularExpression::Pattern.new("[[:upper:]]")).should be_nil
    "\u{FF12}".match(RegularExpression::Pattern.new("[[:upper:]]")).should be_nil
  end

  it "doesn't match Unicode marks with [[:upper:]]" do
    "\u{36F}".match(RegularExpression::Pattern.new("[[:upper:]]")).should be_nil
  end

  it "doesn't match Unicode punctuation characters with [[:upper:]]" do
    "\u{3F}".match(RegularExpression::Pattern.new("[[:upper:]]")).should be_nil
  end

  it "doesn't match Unicode control characters with [[:upper:]]" do
    "\u{16}".match(RegularExpression::Pattern.new("[[:upper:]]")).should be_nil
  end

  it "doesn't match Unicode format characters with [[:upper:]]" do
    "\u{2060}".match(RegularExpression::Pattern.new("[[:upper:]]")).should be_nil
  end

  it "doesn't match Unicode private-use characters with [[:upper:]]" do
    "\u{E001}".match(RegularExpression::Pattern.new("[[:upper:]]")).should be_nil
  end

  it "doesn't match Unicode letter characters [^a-fA-F] with [[:xdigit:]]" do
    "à".match(RegularExpression::Pattern.new("[[:xdigit:]]")).should be_nil
    "g".match(RegularExpression::Pattern.new("[[:xdigit:]]")).should be_nil
    "X".match(RegularExpression::Pattern.new("[[:xdigit:]]")).should be_nil
  end

  it "matches Unicode letter characters [a-fA-F] with [[:xdigit:]]" do
    "a".match(RegularExpression::Pattern.new("[[:xdigit:]]")).to_a.should == ["a"]
    "F".match(RegularExpression::Pattern.new("[[:xdigit:]]")).to_a.should == ["F"]
  end

  it "doesn't match Unicode digits [^0-9] with [[:xdigit:]]" do
    "\u{0660}".match(RegularExpression::Pattern.new("[[:xdigit:]]")).should be_nil
    "\u{FF12}".match(RegularExpression::Pattern.new("[[:xdigit:]]")).should be_nil
  end

  it "doesn't match Unicode marks with [[:xdigit:]]" do
    "\u{36F}".match(RegularExpression::Pattern.new("[[:xdigit:]]")).should be_nil
  end

  it "doesn't match Unicode punctuation characters with [[:xdigit:]]" do
    "\u{3F}".match(RegularExpression::Pattern.new("[[:xdigit:]]")).should be_nil
  end

  it "doesn't match Unicode control characters with [[:xdigit:]]" do
    "\u{16}".match(RegularExpression::Pattern.new("[[:xdigit:]]")).should be_nil
  end

  it "doesn't match Unicode format characters with [[:xdigit:]]" do
    "\u{2060}".match(RegularExpression::Pattern.new("[[:xdigit:]]")).should be_nil
  end

  it "doesn't match Unicode private-use characters with [[:xdigit:]]" do
    "\u{E001}".match(RegularExpression::Pattern.new("[[:xdigit:]]")).should be_nil
  end

  it "matches Unicode lowercase characters with [[:word:]]" do
    "\u{FF41}".match(RegularExpression::Pattern.new("[[:word:]]")).to_a.should == ["\u{FF41}"]
    "\u{1D484}".match(RegularExpression::Pattern.new("[[:word:]]")).to_a.should == ["\u{1D484}"]
    "\u{E8}".match(RegularExpression::Pattern.new("[[:word:]]")).to_a.should == ["\u{E8}"]
  end

  it "matches Unicode uppercase characters with [[:word:]]" do
    "\u{100}".match(RegularExpression::Pattern.new("[[:word:]]")).to_a.should == ["\u{100}"]
    "\u{130}".match(RegularExpression::Pattern.new("[[:word:]]")).to_a.should == ["\u{130}"]
    "\u{405}".match(RegularExpression::Pattern.new("[[:word:]]")).to_a.should == ["\u{405}"]
  end

  it "matches Unicode title-case characters with [[:word:]]" do
    "\u{1F88}".match(RegularExpression::Pattern.new("[[:word:]]")).to_a.should == ["\u{1F88}"]
    "\u{1FAD}".match(RegularExpression::Pattern.new("[[:word:]]")).to_a.should == ["\u{1FAD}"]
    "\u{01C5}".match(RegularExpression::Pattern.new("[[:word:]]")).to_a.should == ["\u{01C5}"]
  end

  it "matches Unicode decimal digits with [[:word:]]" do
    "\u{FF10}".match(RegularExpression::Pattern.new("[[:word:]]")).to_a.should == ["\u{FF10}"]
    "\u{096C}".match(RegularExpression::Pattern.new("[[:word:]]")).to_a.should == ["\u{096C}"]
  end

  it "matches Unicode marks with [[:word:]]" do
    "\u{36F}".match(RegularExpression::Pattern.new("[[:word:]]")).to_a.should == ["\u{36F}"]
  end

  it "match Unicode Nl characters with [[:word:]]" do
    "\u{16EE}".match(RegularExpression::Pattern.new("[[:word:]]")).to_a.should == ["\u{16EE}"]
  end

  it "doesn't match Unicode No characters with [[:word:]]" do
    "\u{17F0}".match(RegularExpression::Pattern.new("[[:word:]]")).should be_nil
  end
  it "doesn't match Unicode punctuation characters with [[:word:]]" do
    "\u{3F}".match(RegularExpression::Pattern.new("[[:word:]]")).should be_nil
  end

  it "doesn't match Unicode control characters with [[:word:]]" do
    "\u{16}".match(RegularExpression::Pattern.new("[[:word:]]")).should be_nil
  end

  it "doesn't match Unicode format characters with [[:word:]]" do
    "\u{2060}".match(RegularExpression::Pattern.new("[[:word:]]")).should be_nil
  end

  it "doesn't match Unicode private-use characters with [[:word:]]" do
    "\u{E001}".match(RegularExpression::Pattern.new("[[:word:]]")).should be_nil
  end

  it "matches unicode named character properties" do
    "a1".match(RegularExpression::Pattern.new("\\p{Alpha}")).to_a.should == ["a"]
  end

  it "matches unicode abbreviated character properties" do
    "a1".match(RegularExpression::Pattern.new("\\p{L}")).to_a.should == ["a"]
  end

  it "matches unicode script properties" do
    "a\u06E9b".match(RegularExpression::Pattern.new("\\p{Arabic}")).to_a.should == ["\u06E9"]
  end

  it "matches unicode Han properties" do
    "松本行弘 Ruby".match(RegularExpression::Pattern.new("\\p{Han}+/", "u")).to_a.should == ["松本行弘"]
  end

  it "matches unicode Hiragana properties" do
    "Ruby（ルビー）、まつもとゆきひろ".match(RegularExpression::Pattern.new("\\p{Hiragana}+/", "u")).to_a.should == ["まつもとゆきひろ"]
  end

  it "matches unicode Katakana properties" do
    "Ruby（ルビー）、まつもとゆきひろ".match(RegularExpression::Pattern.new("\\p{Katakana}+/", "u")).to_a.should == ["ルビ"]
  end

  it "matches unicode Hangul properties" do
    "루비(Ruby)".match(RegularExpression::Pattern.new("\\p{Hangul}+/", "u")).to_a.should == ["루비"]
  end

  ruby_bug "#17340", ''...'3.0' do
    it "raises a RegexpError for an unterminated unicode property" do
      -> { Regexp.new('\p{') }.should raise_error(RegexpError)
    end
  end

  it "supports \\X (unicode 9.0 with UTR #51 workarounds)" do
    # simple emoji without any fancy modifier or ZWJ
    RegularExpression::Pattern.new("\\X").match("\u{1F98A}").to_a.should == ["🦊"]

    # skin tone modifier
    RegularExpression::Pattern.new("\\X").match("\u{1F918}\u{1F3FD}").to_a.should == ["🤘🏽"]

    # emoji joined with ZWJ
    RegularExpression::Pattern.new("\\X").match("\u{1F3F3}\u{FE0F}\u{200D}\u{1F308}").to_a.should == ["🏳️‍🌈"]
    RegularExpression::Pattern.new("\\X").match("\u{1F469}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}").to_a.should == ["👩‍👩‍👧‍👦"]

    # without the ZWJ
    RegularExpression::Pattern.new("\\X+").match("\u{1F3F3}\u{FE0F}\u{1F308}").to_a.should == ["🏳️🌈"]
    RegularExpression::Pattern.new("\\X+").match("\u{1F469}\u{1F469}\u{1F467}\u{1F466}").to_a.should == ["👩👩👧👦"]

    # both of the ZWJ combined
    RegularExpression::Pattern.new("\\X+").match("\u{1F3F3}\u{FE0F}\u{200D}\u{1F308}\u{1F469}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}")
      .to_a.should == ["🏳️‍🌈👩‍👩‍👧‍👦"]
  end
end
