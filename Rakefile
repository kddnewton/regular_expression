# frozen_string_literal: true

require "rake/testtask"

file "lib/regular_expression/parser.rb" do |t|
  `bundle exec racc lib/regular_expression/parser.y -o lib/regular_expression/parser.rb`
end

task default: "lib/regular_expression/parser.rb"
