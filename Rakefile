# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

UNICODE_CACHE = "lib/regular_expression/unicode/cache.txt"

file UNICODE_CACHE do
  require "bundler/setup"

  $:.unshift(File.expand_path("lib", __dir__))
  require "regular_expression"
  require "regular_expression/unicode/generate"

  RegularExpression::Unicode.generate
end

Rake::TestTask.new(test: UNICODE_CACHE) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task default: :test
