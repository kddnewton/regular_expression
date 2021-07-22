# frozen_string_literal: true

module RegularExpression
  # An object to contain the value of the flags that were set when the pattern
  # was initialized. These match up to the Regexp constants.
  class Flags
    attr_reader :value

    def initialize(value = nil)
      @value = value || 0
    end

    # This is the free-spacing mode:
    #
    #   https://ruby-doc.org/core-3.0.0/Regexp.html#class-Regexp-label-Free-Spacing+Mode+and+Comments
    #
    # It means that whitespace and comments are ignored in the body of the
    # regular expression.
    def extended?
      (value & Regexp::EXTENDED).positive?
    end
  end
end
