# frozen_string_literal: true

require "simplecov"
SimpleCov.start

$:.unshift File.expand_path("../lib", __dir__)
require "regular_expression"
require "graphviz"

require "minitest/autorun"
