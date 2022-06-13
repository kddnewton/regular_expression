# frozen_string_literal: true

module RegularExpression
  # This module contains classes that make up the deterministic state machine
  # representation of the regular expression.
  module DFA
    # This represents a state in the deterministic state machine. It contains a
    # sublist of states from the non-deterministic state machine.
    class State
      attr_reader :states, :transitions

      def initialize(states:, transitions: {})
        @states = states
        @transitions = transitions
      end

      def each_transition
        return to_enum(__method__) unless block_given?

        states.each do |state|
          state.transitions.each do |transition, state|
            yield transition, state
          end
        end
      end

      def eql?(other)
        states == other.states
      end

      def final?
        states.any?(&:final?)
      end

      def hash
        states.hash
      end

      def label
        states.map(&:label).join(",")
      end

      def pretty_print(q)
        q.text(label)
      end

      def connect(transition, state)
        @transitions[transition] = state
      end
    end

    # This represents a transition between two states in the DFA that matches
    # against any character.
    class AnyTransition
    end

    # This represents a transition between two states in the DFA that matches
    # against a specific character.
    class CharacterTransition
      attr_reader :value

      def initialize(value:)
        @value = value
      end

      def deconstruct_keys(keys)
        { value: value }
      end
    end

    # This represents a transition between two states in the DFA that accepts
    # any character within a range of values.
    class RangeTransition
      attr_reader :from, :to

      def initialize(from:, to:)
        @from = from
        @to = to
      end

      def deconstruct_keys(keys)
        { from: from, to: to }
      end
    end

    # This class is responsible for compiling an NFA into a DFA.
    class Compiler
      # This method converts a non-deterministic finite automata into a
      # deterministic finite automata. The best link I could find that describes
      # the general approach taken here is here:
      #
      #     https://www.geeksforgeeks.org/conversion-from-nfa-to-dfa/
      #
      # The general idea is to walk the state machine and make it such that
      # for any given state and input you deterministically know which state the
      # machine should transition to. In effect, this means we're removing all
      # epsilon transitions.
      def call(start)
        compiled = State.new(states: expand([start]))

        visited_states = Set.new([compiled])
        queue = [compiled]

        while (state = queue.shift)
          # First, we're going to build up a mapping of states to the alphabet
          # pieces that lead to those states.
          alphabet_states = Hash.new { |hash, key| hash[key] = [] }

          alphabet_for(state).to_a.each do |alphabet|
            states = Set.new

            state.each_transition do |transition, next_state|
              next if transition in NFA::EpsilonTransition
              states << next_state if matches?(alphabet, transition)
            end

            alphabet_states[State.new(states: expand(states.to_a))] << alphabet
          end

          # Next, we're going to add the new states and all of the associated
          # transitions.
          alphabet_states.each do |next_state, alphabets|
            # First, we're going to reduce the alphabets to the minimal set that
            # can be represented. For example if we have a-c and d, then we'll
            # just add a transition that's a-d. This will always result in one
            # alphabet at the most since we have the Multiple class.
            transition_alphabet =
              alphabets.inject(Alphabet::None.new) do |alphabet, next_alphabet|
                Alphabet.combine(alphabet, next_alphabet)
              end

            transition_alphabet.to_a.each do |alphabet|
              connect(state, next_state, alphabet)
            end

            unless visited_states.include?(next_state)
              visited_states << next_state
              queue << next_state
            end
          end
        end

        # Return the start state of the new DFA.
        compiled
      end

      private

      # Determine the alphabet to use for leading out of the given state.
      def alphabet_for(state)
        state.each_transition.inject(Alphabet::None.new) do |alphabet, (transition, _)|
          Alphabet.overlay(
            alphabet,
            case transition
            in NFA::AnyTransition
              Alphabet::Any.new
            in NFA::CharacterTransition[value:]
              Alphabet::Value.new(value: value.ord)
            in NFA::EpsilonTransition
              Alphabet::None.new
            end
          )
        end
      end

      # Creates transitions between two states for the given alphabet.
      def connect(from, to, alphabet)
        case alphabet
        in Alphabet::Any
          from.connect(AnyTransition.new, to)
        in Alphabet::Multiple[alphabets:]
          alphabets.each { |alphabet| connect(from, to, alphabet) }
        in Alphabet::None
        in Alphabet::Range[from: min, to: max]
          from.connect(RangeTransition.new(from: min, to: max), to)
        in Alphabet::Value[value:]
          from.connect(CharacterTransition.new(value: value), to)
        end
      end

      # Get the set of states that correspond to the given set of states but
      # walked through any epsilon transitions. So for example if we have the
      # following NFA which represents the a?a?b language:
      #
      # ─> (1) ─a─> (2) ─a─> (3) ─b─> [4]
      #     └───ε-──^└───ε-───^
      #
      # Then if you passed [1] into here we would return [1,2,3].
      def expand(initial)
        states = [*initial]
        index = 0

        while index < states.length
          states[index].transitions.each do |transition, to|
            if (transition in NFA::EpsilonTransition) && !states.include?(to)
              states << to
            end
          end

          index += 1
        end

        states.sort
      end

      # Check if a given transition accepts the given alphabet.
      def matches?(alphabet, transition)
        case [alphabet, transition]
        in [Alphabet::Any, _] | [_, NFA::AnyTransition]
          true
        in [Alphabet::Range[from:, to:], NFA::CharacterTransition[value:]]
          (from..to).cover?(value.ord)
        in [Alphabet::Value[value: ord], NFA::CharacterTransition[value:]]
          value.ord == ord
        end
      end
    end

    class << self
      # This converts an NFA into a DFA.
      def compile(start)
        Compiler.new.call(start)
      end

      # Checks if the machine matches against the given string at any index in
      # the string.
      def match?(state, string)
        (0..string.length).any? do |index|
          match_at?(state, string, index)
        end
      end

      private

      # Executes the machine against the given string at the given index.
      def match_at?(state, string, index = 0)
        return state.final? if index == string.length

        selected =
          state.transitions.detect do |transition, to|
            case transition
            in DFA::AnyTransition
              break to
            in DFA::CharacterTransition[value:]
              break to if string[index].ord == value
            in DFA::RangeTransition[from: min, to: max]
              break to if (min..max).cover?(string[index].ord)
            end
          end

        (selected && match_at?(selected, string, index + 1)) || state.final?
      end
    end
  end
end
