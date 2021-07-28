# frozen_string_literal: true

# This file exists because we don't currently pass all of the tests in
# ruby/spec. So here we wrap the #it method with some logic to handle cases that
# we know will fail.
#
# If a test fails that is listed under the known failures, then we rescue any
# errors it may have thrown and skip it.
#
# If a test fails that is not listed under the known failures, then we allow
# minitest to handle the error as normal, but report at the end of the test
# suite that that test case should maybe be added to the known failures.
#
# If a test passes that is listed under the known failures, then we allow the
# test to pass but report at the end of the test run that the test should be
# removed from the known failures list.

source_path = "known_failures.txt"
KNOWN_FAILURES = File.readlines(File.expand_path(source_path, __dir__)).map(&:chomp)

NOT_ACTUALLY_FAILURES = [] # rubocop:disable Style/MutableConstant
UNKNOWN_FAILURES = [] # rubocop:disable Style/MutableConstant

Minitest.after_run do
  if NOT_ACTUALLY_FAILURES.any?
    warn(<<~MSG)
      The following ruby/spec specs passed, even though they were listed as \
      known failures. Please remove them from test/#{source_path}.

      #{NOT_ACTUALLY_FAILURES}
    MSG

    exit 1
  end

  if UNKNOWN_FAILURES.any?
    warn(<<~MSG)
      The following ruby/spec specs failed. The skip the warning, add the name \
      of the test to test/#{source_path}.

      #{UNKNOWN_FAILURES}
    MSG

    exit 1
  end
end

module KnownFailuresItExtension
  def it(name, &block)
    define_method("test_ #{name}") do
      block.call
      NOT_ACTUALLY_FAILURES << name if KNOWN_FAILURES.include?(name)
    rescue # rubocop:disable Style/RescueStandardError
      if KNOWN_FAILURES.include?(name)
        skip
      else
        UNKNOWN_FAILURES << name
        raise
      end
    end
  end
end

Minitest::Test.singleton_class.prepend(KnownFailuresItExtension)
