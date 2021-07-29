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

# We're intentionally going to filter out some warnings that we know exist
# because of our use of ruby/spec.
module WarningFilter
  def warn(message, **)
    return if message.include?("possibly useless use of == in void context")

    return if message.include?("assigned but unused variable - str")

    super
  end
end

Warning.extend(WarningFilter)
