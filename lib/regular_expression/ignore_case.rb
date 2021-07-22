# frozen_string_literal: true

module RegularExpression
  module IgnoreCase
    extend self

    def label(string, ignore_case)
      return string unless ignore_case
      "#{string}/i"
    end

    def matches?(char, ignore_case)
      yield(char) || (
        ignore_case &&
          char != (other_char = other_case(char)) &&
          yield(other_char)
      )
    end

    def other_case(char)
      if char != (downcase = char.downcase)
        downcase
      elsif char != (upcase = char.upcase)
        upcase
      end
    end
  end
end
