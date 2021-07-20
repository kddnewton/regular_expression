# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

file "lib/regular_expression/parser.rb" => "lib/regular_expression/parser.y" do
  `bundle exec racc lib/regular_expression/parser.y -o lib/regular_expression/parser.rb`
end

Rake::Task["test"].enhance(["lib/regular_expression/parser.rb"])

task default: :test

task :preflight do
  system("bundle exec rake test") || raise("Tests didn't pass!")
  system("bundle exec rubocop --parallel") || raise("Rubocop failed!")
  system("bundle exec rake benchmark") || raise("Benchmarking failed!")
end

task :benchmark do
  chdir(__dir__) do
    system("bundle exec ruby -I./bench ./bench/run_benchmarks.rb")
  end
end
