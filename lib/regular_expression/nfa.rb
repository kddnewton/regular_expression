# frozen_string_literal: true

module RegularExpression
  # This module contains classes that make up the non-deterministic state
  # machine representation of the regular expression.
  module NFA
    # Represents a single state in the state machine. This is a place where the
    # state machine has transitioned to through accepting various characters.
    class State
      attr_reader :label, :transitions

      def initialize(label:, transitions: {}, final: false)
        @label = label
        @transitions = transitions
        @final = final
      end

      def <=>(other)
        case label
        when "START"
          -1
        else
          label <=> other.label
        end
      end

      def connect(transition, state)
        @transitions[transition] = state
      end

      def final?
        @final
      end
    end

    # This represents a transition between two states in the NFA that accepts
    # any character.
    class AnyTransition
    end

    # This represents a transition between two states in the NFA that matches
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

    # This represents a transition between two states in the NFA that is allowed
    # to transition without matching any characters.
    class EpsilonTransition
    end

    # This class compiles an AST into an NFA.
    class Compiler
      attr_reader :labels

      def initialize
        @labels = ("1"..).each
      end

      def call(pattern)
        start = State.new(label: "START")
        finish = State.new(label: "FINISH", final: true)

        connect(pattern, start, finish)
        start
      end

      private

      # This takes a node in the AST and two states in the NFA and creates
      # whatever transitions it needs to between the two states.
      def connect(node, from, to)
        case node
        in AST::Expression[items: items]
          inner = Array.new(items.length - 1) { State.new(label: labels.next) }
          states = [from, *inner, to]

          items.each_with_index do |item, index|
            connect(item, states[index], states[index + 1])
          end
        in AST::Group
          node.expressions.each do |expression|
            connect(expression, from, to)
          end
        in AST::MatchAny
          from.connect(AnyTransition.new, to)
        in AST::MatchCharacter[value: value]
          from.connect(CharacterTransition.new(value: value), to)
        in AST::MatchClass[name: :digit]
          ("0".."9").each do |value|
            from.connect(CharacterTransition.new(value: value), to)
          end
        in AST::Pattern[expressions: expressions]
          expressions.each do |expression|
            connect(expression, from, to)
          end
        in AST::Quantified[item: item, quantifier: AST::OptionalQuantifier]
          connect(item, from, to)
          from.connect(EpsilonTransition.new, to)
        in AST::Quantified[item: item, quantifier: AST::PlusQuantifier]
          connect(item, from, to)
          to.connect(EpsilonTransition.new, from)
        in AST::Quantified[item: item, quantifier: AST::RangeQuantifier[minimum:, maximum: Float::INFINITY]]
          inner = minimum == 0 ? [] : Array.new(minimum - 1) { State.new(label: labels.next) }
          states = [from, *inner, to]

          minimum.times do |index|
            connect(item, states[index], states[index + 1])
          end

          states[-1].connect(EpsilonTransition.new, states[-2])
        in AST::Quantified[item: item, quantifier: AST::RangeQuantifier[minimum:, maximum:]]
          inner = maximum == 0 ? [] : Array.new(maximum - 1) { State.new(label: labels.next) }
          states = [from, *inner, to]

          maximum.times do |index|
            connect(item, states[index], states[index + 1])
          end

          (maximum - minimum).times do |index|
            states[minimum + index].connect(EpsilonTransition.new, to)
          end
        in AST::Quantified[item: item, quantifier: AST::StarQuantifier]
          connect(item, from, from)
          from.connect(EpsilonTransition.new, to)
        end
      end
    end

    class << self
      # This takes an AST::Pattern node and converts it into an NFA.
      def compile(pattern)
        Compiler.new.call(pattern)
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
        matched =
          state.transitions.any? do |transition, to|
            case transition
            in AnyTransition
              match_at?(to, string, index + 1) if index < string.length
            in CharacterTransition[value:]
              if index < string.length && string[index] == value
                match_at?(to, string, index + 1)
              end
            in EpsilonTransition
              match_at?(to, string, index)
            end
          end

        matched || state.final?
      end
    end
  end
end
