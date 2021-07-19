# frozen_string_literal: true

require_relative "lib/regular_expression/version"

Gem::Specification.new do |spec|
  spec.name          = "regular_expression"
  spec.version       = RegularExpression::VERSION
  spec.authors       = ["Kevin Newton"]
  spec.email         = ["kddnewton@gmail.com"]

  spec.summary       = "Regular expressions in Ruby"
  spec.homepage      = "https://github.com/kddnewton/regular_expression"
  spec.license       = "MIT"

  spec.files         = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "fisk"
  spec.add_dependency "racc"
end
