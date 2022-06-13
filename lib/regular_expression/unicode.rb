# frozen_string_literal: true

module RegularExpression
  module Unicode
    FILEPATH = File.join(__dir__, "unicode", "cache.txt")

    # This represents multiple values in the cache. It is used when other values
    # with the same property are contiguous.
    class Range
      attr_reader :from, :to

      def initialize(from:, to:)
        @from = from
        @to = to
      end

      def deconstruct_keys(keys)
        { from: from, to: to }
      end
    end

    # This represents an individual value in the cache. It is used when other
    # values with the same property are not contiguous.
    class Value
      attr_reader :value

      def initialize(value:)
        @value = value
      end

      def deconstruct_keys(keys)
        { value: value }
      end
    end

    # This class represents the cache of all of the expressions that we have
    # previously calculated within the \p{} syntax. We use this cache to quickly
    # efficiently craft transitions between states using properties.
    class Cache
      attr_reader :entries

      def initialize
        @entries = {}

        File.foreach(FILEPATH, chomp: true) do |line|
          _, name, items = *line.match(/\A\\p\{(.+?)\}\s+(.+)\z/)
          entries[name] = items
        end
      end

      def key?(name)
        entries.key?(name)
      end

      # When you look up an entry using [], it's going to lazily convert each of
      # the entries into an actual object that you can use. It does this so it
      # doesn't waste space allocating a bunch of these objects because most
      # properties are not going to end up being used.
      def [](name)
        entries[name].split(",").map do |entry|
          if entry =~ /\A(\d+)\.\.(\d+)\z/
            Range.new(from: $1.to_i, to: $2.to_i)
          else
            Value.new(value: entry.to_i)
          end
        end
      end
    end

    def self.generate
      URI.open("https://www.unicode.org/Public/#{version}/ucd/UCD.zip") do |file|
        Zip::File.open_buffer(file) do |zipfile|
          File.open(FILEPATH, "w") do |outfile|
            Generate.new(zipfile, outfile).generate
          end
        end
      end
    end

    def self.version
      RbConfig::CONFIG["UNICODE_VERSION"]
    end
  end
end
