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

    # This represents a transition between two states in the NFA that matches
    # against a range of characters.
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

    # This class compiles an AST into an NFA.
    class Compiler
      attr_reader :labels, :unicode

      def initialize
        @labels = ("1"..).each
        @unicode = Unicode::Cache.new
      end

      def call(pattern)
        start = State.new(label: "START")
        finish = State.new(label: "FINISH", final: true)

        connect(pattern, start, finish)
        start
      end

      private

      # Connect between \u{0000} and \u{007F}
      # Bytes are always of the form 0xxxxxxx
      def connect_range_1byte(min, max, from, to)
        from.connect(RangeTransition.new(from: min, to: [0x007F, max].min), to)
      end

      # Connect between \u{0080} and \u{07FF}
      # Bytes are always of the form 110xxxxx 10xxxxxx
      def connect_range_2byte(min, max, from, to)
        byte1_mask = ->(value) { (value >> 6) | 0b11000000 }
        byte2_mask = ->(value) { value & ((1 << 6) - 1) | 0b10000000 }

        byte1_step = 1 << 7

        0x0080.step(0x07FF, byte1_step) do |step|
          if min <= (step + byte1_step) && max >= step
            byte1_transition = CharacterTransition.new(value: byte1_mask[step])
            byte2_transition = RangeTransition.new(from: byte2_mask[[0x0080, min].max], to: byte2_mask[[0x07FF, max].min])

            byte1 = State.new(label: labels.next)

            from.connect(byte1_transition, byte1)
            byte1.connect(byte2_transition, to)
          end
        end
      end

      # Connect between \u{0800} and \u{FFFF}
      # Bytes are always of the form 1110xxxx 10xxxxxx 10xxxxxx
      def connect_range_3byte(min, max, from, to)
        byte1_mask = ->(value) { (value >> 12) | 0b11100000 }
        byte2_mask = ->(value) { (value >> 6) & ((1 << 6) - 1) | 0b10000000 }
        byte3_mask = ->(value) { value & ((1 << 6) - 1) | 0b10000000 }

        byte1_step = 1 << 13
        byte2_step = 1 << 7

        0x0800.step(0xFFFF, byte1_step) do |parent_step|
          if min <= (parent_step + byte1_step) && max >= parent_step
            byte1_transition = CharacterTransition.new(value: byte1_mask[parent_step])

            parent_step.step(parent_step + byte1_step, byte2_step) do |child_step|
              if min <= (child_step + byte2_step) && max >= child_step
                byte2_transition = CharacterTransition.new(value: byte2_mask[child_step])
                byte3_transition = RangeTransition.new(from: byte3_mask[[parent_step, min].max], to: byte3_mask[[(parent_step + byte1_step), max].min])

                byte1 = State.new(label: labels.next)
                byte2 = State.new(label: labels.next)

                from.connect(byte1_transition, byte1)
                byte1.connect(byte2_transition, byte2)
                byte2.connect(byte3_transition, to)
              end
            end
          end
        end
      end

      # Connect between \u{10000} and \u{10FFFF}
      # Bytes are always of the form 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
      def connect_range_4byte(min, max, from, to)
        byte1_mask = ->(value) { (value >> 18) | 0b11100000 }
        byte2_mask = ->(value) { (value >> 12) & ((1 << 6) - 1) | 0b10000000 }
        byte3_mask = ->(value) { (value >> 6) & ((1 << 6) - 1) | 0b10000000 }
        byte4_mask = ->(value) { value & ((1 << 6) - 1) | 0b10000000 }

        byte1_step = 1 << 19
        byte2_step = 1 << 13
        byte3_step = 1 << 7

        0x10000.step(0x10FFFF, byte1_step) do |grand_parent_step|
          if min <= (grand_parent_step + byte1_step) && max >= grand_parent_step
            byte1_transition = CharacterTransition.new(value: byte1_mask[grand_parent_step])

            grand_parent_step.step(grand_parent_step + byte1_step, byte2_step) do |parent_step|
              if min <= (parent_step + byte2_step) && max >= parent_step
                byte2_transition = CharacterTransition.new(value: byte2_mask[parent_step])

                parent_step.step(parent_step + byte2_step, byte3_step) do |child_step|
                  if min <= (child_step + byte3_step) && max >= child_step
                    byte3_transition = CharacterTransition.new(value: byte3_mask[child_step])
                    byte4_transition = RangeTransition.new(from: byte4_mask[[parent_step, min].max], to: byte4_mask[[(parent_step + byte2_step), max].min])

                    byte1 = State.new(label: labels.next)
                    byte2 = State.new(label: labels.next)
                    byte3 = State.new(label: labels.next)

                    from.connect(byte1_transition, byte1)
                    byte1.connect(byte2_transition, byte2)
                    byte2.connect(byte3_transition, byte3)
                    byte3.connect(byte4_transition, to)
                  end
                end
              end
            end
          end
        end
      end

      # Connect a range of values between two states. Similar to connect_value,
      # this also breaks it up into its component bytes, but it's a little
      # harder because we need to mask a bunch of times to get the correct
      # groupings.
      #
      # Below is a table representing how a codepoint is represented in UTF-8.
      # We'll use this to encode the byte sequence into the state transitions
      # so that we can just compare one byte at a time.
      #
      # +-----------+------------+----------+----------+----------+----------+
      # | Minimum   | Maximum    | Byte 1   | Byte 2   | Byte 3   | Byte 4   |
      # +-----------+------------+----------+----------+----------+----------+
      # | \u{0000}  | \u{007F}   | 0xxxxxxx	|          |          |          |
      # | \u{0080}  | \u{07FF}   | 110xxxxx | 10xxxxxx |          |          |
      # | \u{0800}  | \u{FFFF}   | 1110xxxx | 10xxxxxx | 10xxxxxx	|          |
      # | \u{10000} | \u{10FFFF} | 11110xxx | 10xxxxxx | 10xxxxxx | 10xxxxxx |
      # +-----------+------------+----------+----------+----------+----------+
      def connect_range(min, max, from, to)
        connect_range_1byte(min, max, from, to) if min <= 0x007F
        connect_range_2byte(min, max, from, to) if min <= 0x07FF && max >= 0x0080
        connect_range_3byte(min, max, from, to) if min <= 0xFFFF && max >= 0x0800
        connect_range_4byte(min, max, from, to) if max >= 0x10000
      end

      # Connect an individual value between two states. This breaks it up into
      # its byte representation and creates states for each one. Since this is
      # an NFA it's okay for us to duplicate transitions here.
      def connect_value(value, from, to)
        bytes = value.chr(Encoding::UTF_8).bytes
        states = [from, *Array.new(bytes.length - 1) { State.new(label: labels.next) }, to]

        bytes.each_with_index do |byte, index|
          states[index].connect(CharacterTransition.new(value: byte), states[index + 1])
        end
      end

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
          connect_value(value.ord, from, to)
        in AST::MatchClass[name: :digit]
          from.connect(RangeTransition.new(from: "0".ord, to: "9".ord), to)
        in AST::MatchClass[name: :hex]
          from.connect(RangeTransition.new(from: "0".ord, to: "9".ord), to)
          from.connect(RangeTransition.new(from: "A".ord, to: "F".ord), to)
          from.connect(RangeTransition.new(from: "a".ord, to: "f".ord), to)
        in AST::MatchClass[name: :space]
          from.connect(RangeTransition.new(from: "\t".ord, to: "\r".ord), to)
          from.connect(CharacterTransition.new(value: " ".ord), to)
        in AST::MatchClass[name: :word]
          from.connect(RangeTransition.new(from: "0".ord, to: "9".ord), to)
          from.connect(CharacterTransition.new(value: "_".ord), to)
          from.connect(RangeTransition.new(from: "A".ord, to: "Z".ord), to)
          from.connect(RangeTransition.new(from: "a".ord, to: "z".ord), to)
        in AST::MatchProperty[value:]
          unicode[value].each do |entry|
            case entry
            in Unicode::Range[min:, max:]
              connect_range(min, max, from, to)
            in Unicode::Value[value:]
              connect_value(value, from, to)
            end
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

    # This class wraps a set of states and transitions with the ability to
    # execute them against a given input.
    class Machine
      attr_reader :start_state

      def initialize(start_state:)
        @start_state = start_state
      end

      # Executes the machine against the given string.
      def match?(string)
        match_at?(start_state, string, 0)
      end

      private

      def match_at?(state, string, index)
        matched =
          state.transitions.any? do |transition, to|
            case transition
            in AnyTransition
              match_at?(to, string, index + 1) if index < string.length
            in CharacterTransition[value:]
              if index < string.length && string[index].ord == value
                match_at?(to, string, index + 1)
              end
            in EpsilonTransition
              match_at?(to, string, index)
            in RangeTransition[from: range_from, to: range_to]
              if index < string.length && (range_from..range_to).cover?(string[index].ord)
                match_at?(to, string, index + 1)
              end
            end
          end

        matched || state.final?
      end
    end

    # This takes an AST::Pattern node and converts it into an NFA.
    def self.compile(pattern)
      Machine.new(start_state: Compiler.new.call(pattern))
    end
  end
end
