# frozen_string_literal: true

module RegularExpression
  # When we're converting between an NFA and a DFA, we need to transition from
  # a set of states to a new set of states. We determine the new set of states
  # as the union of all the states that can be reached from the old set by
  # applying a transition. We _could_ do this by iterating through every
  # possible value, but this would be time consuming. So instead, we use some
  # objects here to represent different sets of values that should be checked.
  #
  # These objects use the numeric representation of characters instead of the
  # characters themselves. This makes it easier to do math on them.
  module Alphabet
    MINIMUM = 0
    MAXIMUM = 0x10FFFF

    # Matches against the entire alphabet.
    class Any
      def to_a
        [self]
      end

      def minimum
        MINIMUM
      end

      def maximum
        MAXIMUM
      end
    end

    # Matches against a set of multiple child alphabets.
    class Multiple
      attr_reader :alphabets

      def initialize(alphabets:)
        @alphabets = alphabets
      end

      def to_a
        alphabets
      end

      def deconstruct_keys(keys)
        { alphabets: alphabets }
      end

      def minimum
        alphabets.first.minimum
      end

      def maximum
        alphabets.last.maximum
      end

      def self.[](*alphabets)
        alphabets.compact.then do |compacted|
          compacted.one? ? compacted.first : new(alphabets: compacted)
        end
      end
    end

    # Matches nothing.
    class None
      def to_a
        []
      end

      def minimum
        MINIMUM
      end

      def maximum
        MAXIMUM
      end
    end

    # Matches against a range of characters.
    class Range
      attr_reader :from, :to

      def initialize(from:, to:)
        @from = from
        @to = to
      end

      def to_a
        [self]
      end

      def deconstruct_keys(keys)
        { from: from, to: to }
      end

      alias minimum from
      alias maximum to

      def self.[](from, to)
        if to < from
          nil
        elsif from < MINIMUM || to > MAXIMUM
          nil
        elsif from == to
          Value.new(value: from)
        else
          new(from: from, to: to)
        end
      end
    end

    # Matches against a single value.
    class Value
      attr_reader :value

      def initialize(value:)
        @value = value
      end

      def to_a
        [self]
      end

      def deconstruct_keys(keys)
        { value: value }
      end

      alias minimum value
      alias maximum value

      def self.[](value)
        new(value: value)
      end
    end

    def self.overlay(left, right)
      case [left, right].sort_by { |alphabet| [alphabet.class.name, alphabet.minimum, alphabet.maximum] }
      in [Any, Any]
        # [.  .  .  .  .  .  .  .]
        # [.  .  .  .  .  .  .  .]
        # [.  .  .  .  .  .  .  .]
        Any.new
      in [Any, Multiple[alphabets:] => multiple]
        # [.  .  .  .  .  .  .  .]
        # [.]   [.  .]      [.]
        # [.][.][.  .][.  .][.][.]
        next_alphabets = [
          Range[MINIMUM, multiple.minimum - 1],
          multiple.alphabets.first
        ]

        alphabets.each_cons(2) do |(first, second)|
          next_alphabets << Range[first.maximum + 1, second.minimum - 1]
          next_alphabets << second
        end

        next_alphabets << Range[alphabets.last.maximum + 1, MAXIMUM]
        Multiple[*next_alphabets]
      in [Any, None]
        # [.  .  .  .  .  .  .  .]
        #
        # [.  .  .  .  .  .  .  .]
        Any.new
      in [Any, Range[from:, to:]]
        # [.  .  .  .  .  .  .  .]
        #             [.  .  .]
        # [.  .  .  .][.  .  .][.]
        Multiple[Range[MINIMUM, from - 1], Range[from, to], Range[to + 1, MAXIMUM]]
      in [Any, Value[value:]]
        # [.  .  .  .  .  .  .  .]
        #       [.]
        # [.  .][.][.  .  .  .  .]
        Multiple[Range[MINIMUM, value - 1], Value.new(value: value), Range[value + 1, MAXIMUM]]
      in [Multiple, Multiple]
        # [.]   [.  .]      [.]
        #    [.]   [.  .]      [.]
        # [.][.][.][.][.]   [.][.]
        raise NotImplementedError
      in [Multiple[alphabets:], None]
        # [.  .  .  .][.  .  .][.]
        #
        # [.  .  .  .][.  .  .][.]
        Multiple[*alphabets]
      in [Multiple, Range]
        raise NotImplementedError
      in [Multiple[alphabets:] => multiple, Value[value:]] if value < multiple.minimum
        #             [.  .  .][.]
        #       [.]
        #       [.]   [.  .  .][.]
        Multiple[Value[value], *alphabets]
      in [Multiple[alphabets:] => multiple, Value[value:]] if value > multiple.maximum
        #       [.  .  .][.]
        #                      [.]
        #       [.  .  .][.]   [.]
        Multiple[*alphabets, Value[value]]
      in [Multiple[alphabets:], Value[value:]]
        # [.  .  .  .][.  .  .][.]
        #       [.]
        # [.  .][.][.][.  .  .][.]
        index = -1
        matched =
          alphabets.detect do |alphabet|
            index += 1

            case alphabet
            in Range[from:, to:] if (from..to).cover?(value)
              true
            in Value[value: ^value]
              true
            in Range[from:] if from > value
              break
            in Value[value: other_value] if other_value > value
              break
            else
              false
            end
          end

        if matched
          Multiple[
            *alphabets[0...index],
            *overlay(alphabets[index], Value[value]),
            *alphabets[index + 1..-1]
          ]
        else
          Multiple[*alphabets[0...index], Value[value], *alphabets[index..-1]]
        end
      in [None, None]
        #
        #
        #
        None.new
      in [None, Range[from:, to:]]
        #
        #       [.  .  .]
        #       [.  .  .]
        Range[from, to]
      in [None, Value[value:]]
        #
        #       [.]
        #       [.]
        Value[value]
      in [Range, Range]
        raise NotImplementedError
      in [Range[from:, to:], Value[value: ^from]]
        #       [.  .  .]
        #       [.]
        #       [.][.  .]
        Multiple[Value[from], Range[from + 1, to]]
      in [Range[from:, to:], Value[value: ^to]]
        #       [.  .  .]
        #             [.]
        #       [.  .][.]
        Multiple[Range[from, to - 1], Value[to]]
      in [Range[from:, to:], Value[value:]] if (from..to).cover?(value)
        #    [.  .  .  .]
        #          [.]
        #    [.  .][.][.]
        Multiple[Range[from, value - 1], Value[value], Range[value + 1, to]]
      in [Range[from:, to:], Value[value:]] if value < from
        #    [.  .  .  .]
        # [.]
        # [.][.  .  .  .]
        Multiple[Value[value], Range[from, to]]
      in [Range[from:, to:], Value[value:]] if value > to
        #    [.  .  .  .]
        #                [.]
        #    [.  .  .  .][.]
        Multiple[Range[from, to], Value[value]]
      in [Value[value:], Value[value: ^value]]
        #       [.]
        #       [.]
        #       [.]
        Value[value]
      in [Value[value: left_value], Value[value: right_value]]
        #       [.]
        #             [.]
        #       [.]   [.]
        Multiple[Value[left_value], Value[right_value]]
      end
    end
  end
end
