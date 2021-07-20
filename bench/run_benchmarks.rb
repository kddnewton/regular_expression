#!/usr/bin/env ruby

# run_benchmarks.rb

# frozen_string_literal: true

require "benchmark"

require_relative "../lib/regular_expression"

def time_all_matches(source, value, should_match: true, iters: 100)
  samples = {
    metadata: {
      source: source,
      value: value,
      should_match: should_match,
      iters: iters
    }
  }

  # Three RE-gem objects, one basic and two compiled
  re_basic, re_x86, re_ruby = *(1..3).map { RegularExpression::Pattern.new(source) }
  re_x86.compile(compiler: RegularExpression::Compiler::X86)
  re_ruby.compile(compiler: RegularExpression::Compiler::Ruby)

  [
    [ Regexp.new(source), :ruby, "Ruby built-in regexp" ],
    [ re_basic, :re, "uncompiled RegularExpression object"],
    [ re_x86, :re_x86, "RegularExpression x86 compiler"],
    [ re_ruby, :re_ruby, "RegularExpression Ruby compiler"],
  ].each do |match_obj, samples_name, matcher_description|
    if match_obj.match?(value).nil? == should_match
      msg = "Pattern #{source.inspect} should#{should_match ? '' : "n't"} " \
            "match #{value.inspect} with #{matcher_description}!"
      raise msg
    end

    samples[samples_name] = Benchmark.realtime do
      iters.times { match_obj.match?(value) }
    end
  end

  samples
end

s = time_all_matches("ab", "ab", should_match: true, iters: 1_000)

puts s.inspect
