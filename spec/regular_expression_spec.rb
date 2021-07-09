# frozen_string_literal: true

require "regular_expression"

require "rspec"

describe RegularExpression do
  describe "match?" do
    it "matches an optional" do
      pattern = RegularExpression.pattern("ab?c")
      expect(pattern.match?("abc")).to be true
      expect(pattern.match?("abbc")).to be false
      expect(pattern.match?("ac")).to be true
      expect(pattern.match?("abd")).to be false
      expect(pattern.match?("ad")).to be false
    end

    it "matches a zero-or-more" do
      pattern = RegularExpression.pattern("ab*c")
      expect(pattern.match?("abc")).to be true
      expect(pattern.match?("abbc")).to be true
      expect(pattern.match?("ac")).to be true
      expect(pattern.match?("abd")).to be false
      expect(pattern.match?("ad")).to be false
    end

    it "matches a one-or-more" do
      pattern = RegularExpression.pattern("ab+c")
      expect(pattern.match?("abc")).to be true
      expect(pattern.match?("abbc")).to be true
      expect(pattern.match?("ac")).to be false
      expect(pattern.match?("abd")).to be false
      expect(pattern.match?("ad")).to be false
    end
  end
end
