# -*- encoding: binary -*-
require_relative "../rubyspec_helper"

describe "Regexps with escape characters" do
  it "they're supported" do
    RegularExpression::Pattern.new("\t").match("\t").to_a.should == ["\t"] # horizontal tab
    RegularExpression::Pattern.new("\v").match("\v").to_a.should == ["\v"] # vertical tab
    RegularExpression::Pattern.new("\n").match("\n").to_a.should == ["\n"] # newline
    RegularExpression::Pattern.new("\r").match("\r").to_a.should == ["\r"] # return
    RegularExpression::Pattern.new("\f").match("\f").to_a.should == ["\f"] # form feed
    RegularExpression::Pattern.new("\a").match("\a").to_a.should == ["\a"] # bell
    RegularExpression::Pattern.new("\e").match("\e").to_a.should == ["\e"] # escape

    # \nnn         octal char            (encoded byte value)
  end

  it "support quoting meta-characters via escape sequence" do
    RegularExpression::Pattern.new("\\\\").match("\\").to_a.should == ["\\"]
    RegularExpression::Pattern.new("\\/").match("/").to_a.should == ["/"]
    # parenthesis, etc
    RegularExpression::Pattern.new("\\(").match("(").to_a.should == ["("]
    RegularExpression::Pattern.new("\\)").match(")").to_a.should == [")"]
    RegularExpression::Pattern.new("\\[").match("[").to_a.should == ["["]
    RegularExpression::Pattern.new("\\]").match("]").to_a.should == ["]"]
    RegularExpression::Pattern.new("\\{").match("{").to_a.should == ["{"]
    RegularExpression::Pattern.new("\\}").match("}").to_a.should == ["}"]
    # alternation separator
    RegularExpression::Pattern.new("\\|").match("|").to_a.should == ["|"]
    # quantifiers
    RegularExpression::Pattern.new("\\?").match("?").to_a.should == ["?"]
    RegularExpression::Pattern.new("\\.").match(".").to_a.should == ["."]
    RegularExpression::Pattern.new("\\*").match("*").to_a.should == ["*"]
    RegularExpression::Pattern.new("\\+").match("+").to_a.should == ["+"]
    # line anchors
    RegularExpression::Pattern.new("\\^").match("^").to_a.should == ["^"]
    RegularExpression::Pattern.new("\\$").match("$").to_a.should == ["$"]
  end

  it "allows any character to be escaped" do
    RegularExpression::Pattern.new("\\y").match("y").to_a.should == ["y"]
  end

  it "support \\x (hex characters)" do
    RegularExpression::Pattern.new("\\xA").match("\nxyz").to_a.should == ["\n"]
    RegularExpression::Pattern.new("\\x0A").match("\n").to_a.should == ["\n"]
    RegularExpression::Pattern.new("\\xAA").match("\nA").should be_nil
    RegularExpression::Pattern.new("\\x0AA").match("\nA").to_a.should == ["\nA"]
    RegularExpression::Pattern.new("\\xAG").match("\nG").to_a.should == ["\nG"]
    # Non-matches
    -> { eval('/\xG/') }.should raise_error(SyntaxError)

    # \x{7HHHHHHH} wide hexadecimal char (character code point value)
  end

  it "support \\c (control characters)" do
    #/\c \c@\c`/.match("\00\00\00").to_a.should == ["\00\00\00"]
    RegularExpression::Pattern.new("\\c#\\cc\\cC").match("\03\03\03").to_a.should == ["\03\03\03"]
    RegularExpression::Pattern.new("\\c'\\cG\\cg").match("\a\a\a").to_a.should == ["\a\a\a"]
    RegularExpression::Pattern.new("\\c(\\cH\\ch").match("\b\b\b").to_a.should == ["\b\b\b"]
    RegularExpression::Pattern.new("\\c)\\cI\\ci").match("\t\t\t").to_a.should == ["\t\t\t"]
    RegularExpression::Pattern.new("\\c*\\cJ\\cj").match("\n\n\n").to_a.should == ["\n\n\n"]
    RegularExpression::Pattern.new("\\c+\\cK\\ck").match("\v\v\v").to_a.should == ["\v\v\v"]
    RegularExpression::Pattern.new("\\c,\\cL\\cl").match("\f\f\f").to_a.should == ["\f\f\f"]
    RegularExpression::Pattern.new("\\c-\\cM\\cm").match("\r\r\r").to_a.should == ["\r\r\r"]

    RegularExpression::Pattern.new("\\cJ").match("\r").should be_nil

    # Parsing precedence
    RegularExpression::Pattern.new("\\cJ+").match("\n\n").to_a.should == ["\n\n"] # Quantifiers apply to entire escape sequence
    RegularExpression::Pattern.new("\\\\cJ").match("\\cJ").to_a.should == ["\\cJ"]
    -> { eval('/[abc\x]/') }.should raise_error(SyntaxError) # \x is treated as a escape sequence even inside a character class
    # Syntax error
    -> { eval('/\c/') }.should raise_error(SyntaxError)

    # \cx          control char          (character code point value)
    # \C-x         control char          (character code point value)
    # \M-x         meta  (x|0x80)        (character code point value)
    # \M-\C-x      meta control char     (character code point value)
  end

  it "handles three digit octal escapes starting with 0" do
    RegularExpression::Pattern.new("[\\000-\\b]").match("\x00")[0].should == "\x00"
  end

  it "handles control escapes with \\C-x syntax" do
    RegularExpression::Pattern.new("\\C-*\\C-J\\C-j").match("\n\n\n")[0].should == "\n\n\n"
  end

  it "supports the \\K keep operator" do
    RegularExpression::Pattern.new("a\\Kb").match("ab")[0].should == "b"
  end

  it "supports the \\R line break escape" do
    RegularExpression::Pattern.new("\\R").match("\n")[0].should == "\n"
  end
end
