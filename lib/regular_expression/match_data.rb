# frozen_string_literal: true

module RegularExpression
  # This object represents a successful match against an input string. It is
  # created using the original string that was matched against along with the
  # indices that represent the capture groups.
  #
  # Ideally this very closely mirrors that API of the top-level MatchData object
  # so that it's seemless to switch between the two.
  class MatchData
    # This is the original string that was matched against. It can be accessed
    # through the reader but is also used for pre_match and post_match
    # calculations.
    attr_reader :string

    # indices is an array of match indexes. It's a flat array, so to access the
    # indices for $3 for example, you would access elements 6 and 7.
    attr_reader :indices

    # groups is a flat array of captures, from $0, $1, $2, and on.
    attr_reader :groups

    # aliases is a hash of named capture names pointing to an index in the array
    # groups. It's used for the named_captures method as well as the [] method.
    attr_reader :aliases

    def initialize(string, indices, captures)
      @string = string
      @indices = indices

      @groups = []
      @aliases = {}

      indices.each_slice(2).with_index do |(start, finish), index|
        @groups << (start != -1 && finish != -1 ? string[start...finish] : nil)
        @aliases[captures[index]] = index if captures[index].is_a?(String)
      end
    end

    # captures technically doesn't include $0
    def captures
      groups.drop(1)
    end

    def named_captures
      aliases.transform_values { |index| groups[index] }
    end

    def names
      aliases.keys
    end

    def pre_match
      string[0...indices[0]]
    end

    def post_match
      string[indices[1]..]
    end

    # You can use both string and integer keys for [], string will only
    # correspond to the named captures.
    def [](index)
      if !index.is_a?(String)
        groups[index]
      elsif aliases.key?(index)
        groups[aliases[index]]
      else
        raise IndexError, "undefined group name reference: #{index}"
      end
    end

    def values_at(*indices)
      indices.map { |index| self[index] }
    end

    def to_a
      groups
    end

    def size
      groups.size
    end

    def length
      groups.length
    end

    def ==(other)
      other.is_a?(MatchData) &&
        string == other.string &&
        indices == other.indices
    end

    # This method is largely here to mirror the top-level MatchData object. It
    # should look the same except for the class name.
    def inspect
      indexed_aliases = aliases.invert
      keypairs =
        groups.map.with_index do |group, index|
          if index.zero?
            group.inspect
          else
            "#{indexed_aliases.fetch(index, index)}:#{group.inspect}"
          end
        end

      "#<#{self.class.name} #{keypairs.join(' ')}>"
    end
  end
end
