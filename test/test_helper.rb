# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter(%r{^/spec})
end

$:.unshift File.expand_path("../lib", __dir__)
require "regular_expression"
require "graphviz"

unless `which dot`.chomp.end_with?("dot")
  warn "YOU HAVE NOT INSTALLED GRAPHVIZ. We found no 'dot' in your path.\n" \
       "Please install Graphviz if you want dotfile visual output to work."
end

require "minitest/autorun"

# We're going to filter out the == in a void context warnings as they're
# actually intentionally used by the specs. Doing this first so that we don't
# get any warnings when the test files are required.
module DoubleEqualVoidWarningFilter
  def warn(message, **)
    return if message.include?("possibly useless use of == in void context")

    super
  end
end

Warning.extend(DoubleEqualVoidWarningFilter)
