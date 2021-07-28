# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_{spec,test}.rb"]
end

file "lib/regular_expression/parser.rb" => "lib/regular_expression/parser.y" do
  system("bundle exec racc lib/regular_expression/parser.y -o lib/regular_expression/parser.rb")
end

rule %r{test/rubyspec/.*?_spec.rb} => "spec/language/regexp/%f" do |t|
  system("bin/spec #{t.source} #{t.name}")
end

desc "Run the necessary preflight checks that will run in CI"
task :preflight do
  system("bundle exec rake test") || raise("Tests didn't pass!")
  system("bundle exec rubocop --parallel") || raise("Rubocop failed!")
  system("bundle exec rake benchmark") || raise("Benchmarking failed!")
end

desc "Run the benchmarks for all the various backends"
task :benchmark do
  chdir(__dir__) do
    system("bundle exec ruby -I./bench ./bench/run_benchmarks.rb")
  end
end

# We're going to skip the encoding spec because it has nested regex and our
# convert script can't really handle that at the moment.
rubyspecs = FileList["spec/language/regexp/*_spec.rb"].exclude(/encoding_spec/)

# Here we make sure that every filepath in the ruby/spec submodule is dependent
# on bin/spec so that when we change the generation script all of the spec files
# get regenerated.
rubyspecs.each { |filepath| Rake::Task[filepath].enhance(["bin/spec"]) }

task default: [
  "lib/regular_expression/parser.rb",
  *rubyspecs.pathmap("test/rubyspec/%f"),
  :test
]
