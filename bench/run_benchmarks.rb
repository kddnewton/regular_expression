#!/usr/bin/env ruby

# run_benchmarks.rb

# frozen_string_literal: true

require "benchmark"

require_relative "../lib/regular_expression"

# Individual benchmarks are in the format:
#     [ pattern, value_to_match, should_match, num_iters_per_batch ]

BENCHMARKS = {
  "basics" => [
    ["ab", "ab", true, 10_000],
    ["ab", "ac", false, 10_000],
    ["(ab){2,5}", "ababab", true, 10_000]
  ]
}.freeze

NUM_BATCHES = 5

def time_all_matches(source, value, should_match: true, iters_per_batch: 100)
  samples = {
    metadata: {
      source: source,
      value: value,
      should_match: should_match,
      iters_per_batch: iters_per_batch,
      num_batches: NUM_BATCHES
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

    samples[samples_name] = (0...NUM_BATCHES).map do
      Benchmark.realtime do
        iters_per_batch.times { match_obj.match?(value) }
      end
    end
  end

  samples
end

def mean(values)
  values.sum(0.0) / values.size
end

def stddev(values)
  xbar = mean(values)
  diff_sqrs = values.map { |v| (v - xbar) * (v - xbar) }
  # Bessel's correction requires dividing by length - 1, not just length:
  # https://en.wikipedia.org/wiki/Standard_deviation#Corrected_sample_standard_deviation
  variance = diff_sqrs.sum(0.0) / (values.length - 1)
  Math.sqrt(variance)
end

def format_as_table(header, sample_rows, row_fmt)
  if header.size != row_fmt.size
    raise "Header and row format don't agree on the number of columns!"
  end

  if sample_rows.any? { |row| row.size != header.size }
    raise "Samples rows are not all the same size as the header!"
  end

  # First convert rows to strings with correct significant digits
  formatted_rows = sample_rows.map { |row| row_fmt.zip(row).map { |fmt, item| item.nil? ? "" : format(fmt, item) } }

  # Then space all those rows out according to column widths
  col_widths = (0...header.size).map do |col_num|
    (formatted_rows.map { |row| row[col_num].size } + [header[col_num].size]).max
  end
  row_space_fmt = col_widths.map { |cw| "%#{cw}s" }
  spaced_rows = formatted_rows.map { |row| row_space_fmt.zip(row).map { |fmt, item| format(fmt, item) }.join("   ") }

  header_str = row_space_fmt.zip(header).map { |fmt, item| format(fmt, item) }.join("   ")

  ([header_str] + [""] + spaced_rows).join("\n")
end

report_rows = []

BENCHMARKS.each do |category, benchmarks|
  category_total_times = [0.0, 0.0, 0.0, 0.0]

  samples = benchmarks.map do |pattern, value, should_match, iters_per_batch|
    time_all_matches(pattern,
                     value,
                     should_match: should_match,
                     iters_per_batch: iters_per_batch)
  end

  (0...benchmarks.size).each do |bench_idx|
    pattern = benchmarks[bench_idx][0]
    bench_samples = samples[bench_idx]

    bench_pcts = []
    bench_means = []
    bench_rsds = []
    %i[ruby re re_x86 re_ruby].each_with_index do |impl, impl_idx|
      impl_bench_samples = bench_samples[impl]
      samples_sum = impl_bench_samples.sum
      samples_mean = samples_sum / impl_bench_samples.size
      samples_stddev = stddev(impl_bench_samples)
      rel_stddev_pct = 100.0 * samples_stddev / samples_mean

      bench_means.push samples_mean
      bench_pcts.push(100.0 * bench_means[0] / samples_mean)
      bench_rsds.push rel_stddev_pct

      category_total_times[impl_idx] += samples_sum
    end

    bench_label = format("%8s", "re: #{pattern}")[0..7]

    report_rows.push [bench_label] + bench_pcts + bench_rsds + [bench_means[0]]
  end

  # For implementations, give their speed as a percentage of Ruby native time
  category_pct = category_total_times.map { |time| 100.0 * category_total_times[0] / time }
  ruby_total_ms = category_total_times[0] * 1000.0

  # The final column is the number of milliseconds taken by the Ruby native regexps
  report_rows.push [category] + category_pct + [nil] * 4 + [ruby_total_ms]
end

header = ["category", "ruby (%)", "re (%)", "re_x86 (%)", "re_ruby (%)", "ruby RSD", "re RSD",
          "re_x86 RSD", "re_ruby RSD", "ruby time (ms)"]
row_f = ["%s"] + ["%.1f"] * 4 + ["%.2f"] * 4 + ["%.2e"]

puts
puts format_as_table(header, report_rows, row_f)
puts
puts "Percentages are percentage of the speed of Ruby native regular expressions. Bigger is faster."
puts "Times in ms are per batch of samples for benchmarks, and total for all batches for categories."
puts "RSD is relative standard deviation (stddev divided by mean) given as a percent. " \
     "Smaller is more stable/predictable."
