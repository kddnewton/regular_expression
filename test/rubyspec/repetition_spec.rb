require_relative "../rubyspec_helper"

describe "Regexps with repetition" do
  it "supports * (0 or more of previous subexpression)" do
    RegularExpression::Pattern.new("a*").match("aaa").to_a.should == ["aaa"]
    RegularExpression::Pattern.new("a*").match("bbb").to_a.should == [""]
    RegularExpression::Pattern.new("<.*>").match("<a>foo</a>").to_a.should == ["<a>foo</a>"] # it is greedy
  end

  it "supports *? (0 or more of previous subexpression - lazy)" do
    RegularExpression::Pattern.new("a*?").match("aaa").to_a.should == [""]
    RegularExpression::Pattern.new("<.*?>").match("<a>foo</a>").to_a.should == ["<a>"]
  end

  it "supports + (1 or more of previous subexpression)" do
    RegularExpression::Pattern.new("a+").match("aaa").to_a.should == ["aaa"]
    RegularExpression::Pattern.new("a+").match("bbb").should be_nil
    RegularExpression::Pattern.new("<.+>").match("<a>foo</a>").to_a.should == ["<a>foo</a>"] # it is greedy
  end

  it "supports +? (0 or more of previous subexpression - lazy)" do
    RegularExpression::Pattern.new("a+?").match("aaa").to_a.should == ["a"]
    RegularExpression::Pattern.new("<.+?>").match("<a>foo</a>").to_a.should == ["<a>"]
  end

  it "supports {m,n} (m to n of previous subexpression)" do
    RegularExpression::Pattern.new("a{2,4}").match("aaaaaa").to_a.should == ["aaaa"]
    RegularExpression::Pattern.new("<.{1,}>").match("<a>foo</a>").to_a.should == ["<a>foo</a>"] # it is greedy
  end

  it "supports {m,n}? (m to n of previous subexpression) - lazy)" do
    RegularExpression::Pattern.new("<.{1,}?>").match("<a>foo</a>").to_a.should == ["<a>"]
    RegularExpression::Pattern.new(".([0-9]){3,5}?foo").match("9876543210foo").to_a.should == ["543210foo", "0"]
  end

  it "does not treat {m,n}+ as possessive" do
    -> {
      @regexp = eval "/foo(A{0,1}+)Abar/"
    }.should complain(RegularExpression::Pattern.new("nested repeat operator"))
    @regexp.match("fooAAAbar").to_a.should == ["fooAAAbar", "AA"]
  end

  it "supports ? (0 or 1 of previous subexpression)" do
    RegularExpression::Pattern.new("a?").match("aaa").to_a.should == ["a"]
    RegularExpression::Pattern.new("a?").match("bbb").to_a.should == [""]
  end

  it "handles incomplete range quantifiers" do
    RegularExpression::Pattern.new("a{}").match("a{}")[0].should == "a{}"
    RegularExpression::Pattern.new("a{,}").match("a{,}")[0].should == "a{,}"
    RegularExpression::Pattern.new("a{1").match("a{1")[0].should == "a{1"
    RegularExpression::Pattern.new("a{1,2").match("a{1,2")[0].should == "a{1,2"
    RegularExpression::Pattern.new("a{,5}").match("aaa")[0].should == "aaa"
  end

  it "lets us use quantifiers on assertions" do
    RegularExpression::Pattern.new("a^?b").match("ab")[0].should == "ab"
    RegularExpression::Pattern.new("a$?b").match("ab")[0].should == "ab"
    RegularExpression::Pattern.new("a\\A?b").match("ab")[0].should == "ab"
    RegularExpression::Pattern.new("a\\Z?b").match("ab")[0].should == "ab"
    RegularExpression::Pattern.new("a\\z?b").match("ab")[0].should == "ab"
    RegularExpression::Pattern.new("a\\G?b").match("ab")[0].should == "ab"
    RegularExpression::Pattern.new("a\\b?b").match("ab")[0].should == "ab"
    RegularExpression::Pattern.new("a\\B?b").match("ab")[0].should == "ab"
    RegularExpression::Pattern.new("a(?=c)?b").match("ab")[0].should == "ab"
    RegularExpression::Pattern.new("a(?!=b)?b").match("ab")[0].should == "ab"
    RegularExpression::Pattern.new("a(?<=c)?b").match("ab")[0].should == "ab"
    RegularExpression::Pattern.new("a(?<!a)?b").match("ab")[0].should == "ab"
  end

  it "does not delete optional assertions" do
    RegularExpression::Pattern.new("(?=(a))?").match("a").to_a.should == [ "", "a" ]
  end

  it "supports nested quantifiers" do
    suppress_warning do
      eval <<-RUBY
      /a***/.match("aaa")[0].should == "aaa"

      # a+?* should not be reduced, it should be equivalent to (a+?)*
      # NB: the capture group prevents regex engines from reducing the two quantifiers
      # https://bugs.ruby-lang.org/issues/17341
      /a+?*/.match("")[0].should == ""
      /(a+?)*/.match("")[0].should == ""

      /a+?*/.match("a")[0].should == "a"
      /(a+?)*/.match("a")[0].should == "a"

      ruby_bug '#17341', ''...'3.0' do
        /a+?*/.match("aa")[0].should == "aa"
      end
      /(a+?)*/.match("aa")[0].should == "aa"

      # a+?+ should not be reduced, it should be equivalent to (a+?)+
      # https://bugs.ruby-lang.org/issues/17341
      /a+?+/.match("").should == nil
      /(a+?)+/.match("").should == nil

      /a+?+/.match("a")[0].should == "a"
      /(a+?)+/.match("a")[0].should == "a"

      ruby_bug '#17341', ''...'3.0' do
        /a+?+/.match("aa")[0].should == "aa"
      end
      /(a+?)+/.match("aa")[0].should == "aa"

      # both a**? and a+*? should be equivalent to (a+)??
      # this quantifier would rather match nothing, but if that's not possible,
      # it will greedily take everything
      /a**?/.match("")[0].should == ""
      /(a*)*?/.match("")[0].should == ""
      /a+*?/.match("")[0].should == ""
      /(a+)*?/.match("")[0].should == ""
      /(a+)??/.match("")[0].should == ""

      /a**?/.match("aaa")[0].should == ""
      /(a*)*?/.match("aaa")[0].should == ""
      /a+*?/.match("aaa")[0].should == ""
      /(a+)*?/.match("aaa")[0].should == ""
      /(a+)??/.match("aaa")[0].should == ""

      /b.**?b/.match("baaabaaab")[0].should == "baaabaaab"
      /b(.*)*?b/.match("baaabaaab")[0].should == "baaabaaab"
      /b.+*?b/.match("baaabaaab")[0].should == "baaabaaab"
      /b(.+)*?b/.match("baaabaaab")[0].should == "baaabaaab"
      /b(.+)??b/.match("baaabaaab")[0].should == "baaabaaab"
      RUBY
    end
  end

  it "treats ? after {n} quantifier as another quantifier, not as non-greedy marker" do
    RegularExpression::Pattern.new("a{2}?").match("").to_a.should == [""]
  end

  it "matches zero-width capture groups in optional iterations of loops" do
    RegularExpression::Pattern.new("()?").match("").to_a.should == ["", ""]
    RegularExpression::Pattern.new("(a*)?").match("").to_a.should == ["", ""]
    RegularExpression::Pattern.new("(a*)*").match("").to_a.should == ["", ""]
    RegularExpression::Pattern.new("(?:a|()){500,1000}").match("a" * 500).to_a.should == ["a" * 500, ""]
  end
end
