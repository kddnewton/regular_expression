# frozen_string_literal: true

module RegularExpression
  # An object to contain the value of the flags that were set when the pattern
  # was initialized. These match up to the Regexp constants.
  class Flags
    attr_reader :value

    CODES = {
      "x" => Regexp::EXTENDED
    }.freeze

    # Parses a String into a Flags object.
    def self.parse(string = nil)
      flags =
        (string || "").each_char.map do |flag|
          CODES.fetch(flag) { raise ArgumentError, "Unsupported flag: #{flag}" }
        end

      new(flags.reduce(&:|))
    end

    def initialize(value = nil)
      @value = value || 0
    end

    def ==(other)
      other.is_a?(Flags) && value == other.value
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
