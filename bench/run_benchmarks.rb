#!/usr/bin/env ruby

# run_benchmarks.rb

# frozen_string_literal: true

require "benchmark"

require_relative "../lib/regular_expression"

# Individual benchmarks are in the format:
#     [ pattern, value_to_match, should_match, num_iters ]

BENCHMARKS = {
  "basics" => [
    ["ab", "ab", true, 1_000],
    ["ab", "ac", false, 1_000]
  ]
}.freeze

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
    [Regexp.new(source), :ruby, "Ruby built-in regexp"],
    [re_basic, :re, "uncompiled RegularExpression object"],
    [re_x86, :re_x86, "RegularExpression x86 compiler"],
    [re_ruby, :re_ruby, "RegularExpression Ruby compiler"]
  ].each do |match_obj, samples_name, matcher_description|
    did_match = match_obj.match?(value)

    # We check inverted match values because false isn't the same as nil,
    # and Rubocop hates double-not.
    if !did_match != !should_match
      warn "did_match: #{did_match.inspect}    should_match: #{should_match.inspect}"
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

def format_as_table(header, sample_rows, row_fmt)
  if header.size != row_fmt.size
    raise "Header and row format don't agree on the number of columns!"
  end

  if sample_rows.any? { |row| row.size != header.size }
    raise "Samples rows are not all the same size as the header!"
  end

  # First convert rows to strings with correct significant digits
  formatted_rows = sample_rows.map { |row| row_fmt.zip(row).map { |fmt, item| fmt % item } }

  # Then space all those rows out according to column widths
  col_widths = (0...header.size).map do |col_num|
    (formatted_rows.map { |row| row[col_num].size } + [header[col_num].size]).max
  end
  row_space_fmt = col_widths.map { |cw| "%#{cw}s" }
  spaced_rows = formatted_rows.map { |row| row_space_fmt.zip(row).map { |fmt, item| fmt % item }.join("  ") }

  header_str = row_space_fmt.zip(header).map { |fmt, item| fmt % item }.join("  ")

  ([header_str] + [""] + spaced_rows).join("\n")
end

category_rows = []

BENCHMARKS.each do |category, benchmarks|
  samples = benchmarks.map do |pattern, value, should_match, iters|
    time_all_matches(pattern, value, should_match: should_match, iters: iters)
  end

  category_total_times = %i[ruby re re_x86 re_ruby].map do |impl|
    samples.map { |s| s[impl] }.sum
  end
  # For implementations, give their speed as a percentage of Ruby native time
  category_pct = category_total_times.map { |time| category_total_times[0] * 100.0 / time }
  ruby_total_ms = category_total_times[0] * 1000.0

  # The final column is the number of milliseconds taken by the Ruby native regexps
  category_rows.push [category] + category_pct + [ruby_total_ms]
end

header = ["category", "ruby (%)", "re (%)", "re_x86 (%)", "re_ruby (%)", "ruby (ms)"]
row_f = ["%s"] + ["%.1f"] * 4 + ["%.2e"]

puts
puts format_as_table(header, category_rows, row_f)
puts
puts "Percentages are percentage of the speed of Ruby native regular expressions. Bigger is better."
