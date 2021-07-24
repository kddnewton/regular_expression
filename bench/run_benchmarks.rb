#!/usr/bin/env ruby

# run_benchmarks.rb

# frozen_string_literal: true

require "benchmark"

require_relative "../lib/regular_expression"

# Individual benchmarks are in the format:
#     [ pattern, value_to_match, should_match, num_iters_per_batch ]

# Large x86-compiled benchmarks segfault due to https://github.com/kddnewton/regular_expression/issues/74

BENCHMARKS = {
  "basics" => [
    [%q{ab}, "ab", true, 10_000],
    [%q{ab}, "ac", false, 10_000],
    [%q{ab{2,5}}, "ababab", false, 10_000],
  ],
  "large string" => [
    [%Q{#{'a' * 20}b}, "#{'a' * 20}b", true, 1_000],
    [%q{a{25,50}}, "a" * 37, true, 1_000],
    [%q{a{25,50}b}, "#{'a' * 37}b", true, 1_000],
    [%q{a{25,50}b}, "#{'a' * 37}c", false, 1_000],
  ],
  "tricky" => [
    [%q{(a?){10}a{10}}, "a" * 15, true, 1_000,
     { uncompiled: false, compiled_x86: false, compiled_ruby: false, compiled_cranelift: false }],
    [%Q{#{'a?' * 10}#{'a' * 10}}, "a" * 15, true, 1_000,
     { uncompiled: false, compiled_x86: false, compiled_ruby: false, compiled_cranelift: false }]
  ],

  # Benchmarks from Shopify's UserAgent sniffing code
  "sniffer" => [
    [
      %q{.*Shopify Mobile\/(iPhone\sOS|iOS)\/[\d\.]+ \(.*\/OperatingSystemVersion\((.*)\)},
      "Shopify Mobile/iOS/5.4.4 "\
      "(iPhone9,3/com.jadedpixel.shopify/OperatingSystemVersion(majorVersion: 10, minorVersion: 3, patchVersion: 2))",
      true, 100,
      { uncompiled: false, compiled_x86: false, compiled_ruby: false, compiled_cranelift: false }
    ]
  ]
}.freeze

NUM_BATCHES = 5

def time_all_matches(source, value, should_match: true, iters_per_batch: 100, options: {})
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
  begin
    re_basic, re_x86, re_ruby, re_cranelift = *(1..4).map { RegularExpression::Pattern.new(source) }
    re_x86.compile(compiler: RegularExpression::Compiler::X86) unless options[:compiled_x86] == false
    re_ruby.compile(compiler: RegularExpression::Compiler::Ruby) unless options[:compiled_ruby] == false
    re_cranelift.compile(compiler: RegularExpression::Compiler::Cranelift) unless options[:compiled_cranelift] == false
  rescue StandardError
    warn "Exception when building RE objects for regexp (#{source.inspect} / #{value.inspect})"
    raise
  end

  [
    [Regexp.new(source), :ruby, "Ruby built-in regexp"],
    [re_basic, :re, "uncompiled RegularExpression object"],
    [re_x86, :re_x86, "RegularExpression x86 compiler"],
    [re_ruby, :re_ruby, "RegularExpression Ruby-backend compiler"],
    [re_cranelift, :re_cranelift, "RegularExpression cranelift compiler"]
  ].each do |match_obj, samples_name, matcher_description|
    next if samples_name == :ruby && options[:native] == false
    next if samples_name == :re && options[:uncompiled] == false
    next if samples_name == :re_x86 && options[:compiled_x86] == false
    next if samples_name == :re_ruby && options[:compiled_ruby] == false
    next if samples_name == :re_cranelift && options[:compiled_cranelift] == false

    did_match = match_obj.match?(value)

    # We check inverted match values because false isn't the same as nil,
    # and Rubocop hates double-not.
    if did_match != should_match
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
  category_total_times = [0.0, 0.0, 0.0, 0.0, 0.0]

  samples = benchmarks.map do |pattern, value, should_match, iters_per_batch, options|
    time_all_matches(pattern,
                     value,
                     should_match: should_match,
                     iters_per_batch: iters_per_batch,
                     options: options || {})
  end

  (0...benchmarks.size).each do |bench_idx|
    pattern, _, _, _, options = *benchmarks[bench_idx]
    options ||= {}
    bench_samples = samples[bench_idx]

    bench_pcts = []
    bench_means = []
    bench_rsds = []
    %i[ruby re re_x86 re_ruby re_cranelift].each_with_index do |impl, impl_idx|
      if (impl == :ruby && options[:native] == false) ||
         (impl == :re && options[:uncompiled] == false) ||
         (impl == :re_x86 && options[:compiled_x86] == false) ||
         (impl == :re_ruby && options[:compiled_ruby] == false) ||
         (impl == :re_cranelift && options[:compiled_cranelift] == false)
        bench_pcts.push nil
        bench_rsds.push nil
        next
      end

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

    bench_label = format("%16s", "re: #{pattern}")[0..15]

    report_rows.push [bench_label] + bench_pcts + bench_rsds + [bench_means[0]]
  end

  # For implementations, give their speed as a percentage of Ruby native time
  category_pct = category_total_times.map { |time| 100.0 * category_total_times[0] / time }
  ruby_total_ms = category_total_times[0] * 1000.0

  # The final column is the number of milliseconds taken by the Ruby native regexps
  report_rows.push [category] + category_pct + [nil] * 5 + [ruby_total_ms]
end

puts "Finished running..."

header = ["category", "ruby (%)", "re (%)", "re_x86 (%)", "re_ruby (%)", "re_cranelift (%)", "ruby RSD", "re RSD",
          "re_x86 RSD", "re_ruby RSD", "re_cranelift RSD", "ruby time (ms)"]
row_f = ["%s"] + ["%.1f"] * 5 + ["%.2f"] * 5 + ["%.2e"]

puts
puts format_as_table(header, report_rows, row_f)
puts
puts "Percentages are percentage of the speed of Ruby native regular expressions. Bigger is faster."
puts "Times in ms are per batch of samples for benchmarks, and total for all batches for categories."
puts "RSD is relative standard deviation (stddev divided by mean) given as a percent. " \
     "Smaller is more stable/predictable."
