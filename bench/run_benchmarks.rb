#!/usr/bin/env ruby

# run_benchmarks.rb

require "benchmark"

require_relative "../lib/regular_expression"

def time_all_matches(source, value, should_match: true, iters: 100)
	samples = {
		metadata: {
			source: source,
			value: value,
			should_match: should_match,
			iters: iters,
		},

		# Normal Ruby regexps
		ruby: nil,

		# Regular_expression gem with various compilers
		re: nil,
		re_x86: nil,
		re_ruby: nil,
	}

	ruby_regexp = Regexp.new(source)
	unless !!ruby_regexp.match?(value) == should_match
		raise "Pattern #{source.inspect} should#{ should_match ? "" : "n't" } match #{value.inspect} with Ruby built-in regexp!"
	end
	samples[:ruby] = Benchmark.realtime do
		iters.times { ruby_regexp.match?(value) }
	end

	pattern = RegularExpression::Pattern.new(source)
	unless !!pattern.match?(value) == should_match
		raise "Pattern #{source.inspect} should#{ should_match ? "" : "n't" } match #{value.inspect} with plain RegularExpression object!"
	end
	samples[:re] = Benchmark.realtime do
		iters.times { pattern.match?(value) }
	end

	pattern.compile(compiler: RegularExpression::Compiler::X86)
	unless !!pattern.match?(value) == should_match
		raise "Pattern #{source.inspect} should#{ should_match ? "" : "n't" } match #{value.inspect} with RegularExpression x86 compiler!"
	end
	samples[:re_x86] = Benchmark.realtime do
		iters.times { pattern.match?(value) }
	end

	pattern.compile(compiler: RegularExpression::Compiler::Ruby)
	unless !!pattern.match?(value) == should_match
		raise "Pattern #{source.inspect} should#{ should_match ? "" : "n't" } match #{value.inspect} with RegularExpression Ruby compiler!"
	end
	samples[:re_ruby] = Benchmark.realtime do
		iters.times { pattern.match?(value) }
	end

	samples
end

s = time_all_matches("ab", "ab", should_match: true, iters: 1_000)

puts s.inspect
