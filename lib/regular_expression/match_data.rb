# frozen_string_literal: true

module RegularExpression
  # This object represents a successful match against an input string. It is
  # created using the original string that was matched against along with the
  # indices that represent the capture groups.
  #
  # Ideally this very closely mirrors that API of the top-level MatchData object
  # so that it's seemless to switch between the two.
  class MatchData
    attr_reader :string, :indices, :groups, :aliases

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

    def captures
      groups.drop(1)
    end

    def named_captures
      aliases.to_h { |name, index| [name, groups[index]] }
    end

    def names
      aliases.keys
    end

    def pre_match
      string[0...indices[0]]
    end

    def post_match
      string[indices[1]..-1]
    end

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
      string == other.string && indices == other.indices
    end
  
    def inspect
      indexed_aliases = aliases.invert
      keypairs =
        groups.map.with_index do |group, index|
          if index == 0
            group.inspect
          else
            "#{indexed_aliases.fetch(index, index)}:#{group.inspect}"
          end
        end

      "#<#{self.class.name} #{keypairs.join(" ")}>"
    end
  end
end
