# frozen_string_literal: true

require_relative "./test_helper"

require_relative "./rubyspec/mspec"
require_relative "./rubyspec/known_failures"
require_relative "./rubyspec/language_specs"

module RegularExpression
  # Patch string so that it can match against our own regexp classes. We're only
  # going to do this in tests as I don't want to actually monkey-patch string
  # with our library.
  module StringExtension
    def match(pattern)
      pattern.is_a?(Pattern) ? pattern.match(self) : super
    end
  end
end

String.prepend(RegularExpression::StringExtension)
