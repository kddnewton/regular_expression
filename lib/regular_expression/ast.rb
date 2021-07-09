# frozen_string_literal: true

module RegularExpression
  module AST
    def self.to_dot(root)
      require "graphviz"
      graph = Graphviz::Graph.new
      root.to_dot(graph)

      Graphviz.output(graph, path: "build/ast.svg", format: "svg")
      graph.to_dot
    end

    class Root
      attr_reader :expressions # Array[Expression]
      attr_reader :at_start # bool

      def initialize(expressions, at_start: false)
        @expressions = expressions
        @at_start = at_start
      end

      def to_dot(graph)
        label = "Root"
        label = "#{label} (at start)" if at_start

        node = graph.add_node(object_id, label: label)
        expressions.each { |expression| expression.to_dot(node) }
      end

      def to_nfa
        start = NFA::StartState.new
        current = start

        if at_start
          current = NFA::State.new
          start.add_transition(NFA::Transition::BeginAnchor.new(current))
        end

        finish = NFA::FinishState.new
        expressions.each do |expression|
          expression.to_nfa(current, finish)
        end

        start
      end
    end

    class Expression
      attr_reader :items # Group | Match | Anchor

      def initialize(items)
        @items = items
      end

      def to_dot(parent)
        node = parent.add_node(object_id, label: "Expression")

        items.each { |item| item.to_dot(node) }
      end

      def to_nfa(start, finish)
        inner = Array.new(items.length - 1) { NFA::State.new }
        states = [start, *inner, finish]

        items.each_with_index do |item, index|
          item.to_nfa(states[index], states[index + 1])
        end
      end
    end

    class Group
      attr_reader :expressions # Array[Expression]
      attr_reader :quantifier # Quantifier

      def initialize(expressions, quantifier: Quantifier::Once.new)
        @expressions = expressions
        @quantifier = quantifier
      end

      def to_dot(parent)
        node = parent.add_node(object_id, label: "Group")

        expressions.each { |expression| expression.to_dot(node) }
        quantifier.to_dot(node)
      end

      def to_nfa(start, finish)
        quantifier.quantify(start, finish) do |start, finish|
          expressions.each { |expression| expression.to_nfa(start, finish) }
        end
      end
    end

    class Match
      attr_reader :item # CharacterGroup | CharacterClass | Character | Period
      attr_reader :quantifier # Quantifier

      def initialize(item, quantifier: Quantifier::Once.new)
        @item = item
        @quantifier = quantifier
      end

      def to_dot(parent)
        node = parent.add_node(object_id, label: "Match")

        item.to_dot(node)
        quantifier.to_dot(node) if quantifier
      end

      def to_nfa(start, finish)
        quantifier.quantify(start, finish) do |start, finish|
          item.to_nfa(start, finish)
        end
      end
    end

    class CharacterGroup
      attr_reader :items # Array[CharacterRange | Character]
      attr_reader :invert # bool

      def initialize(items, invert: false)
        @items = items
        @invert = invert
      end

      def to_dot(parent)
        label = "CharacterGroup"
        label = "#{label} (invert)" if invert

        node = parent.add_node(object_id, label: label)
        items.each { |item| item.to_dot(node) }
      end

      def to_nfa(start, finish)
        values = items.flat_map(&:to_nfa_values).sort
        transition = NFA::Transition::Set.new(finish, values, invert: invert)
        start.add_transition(transition)
      end
    end

    class CharacterClass
      attr_reader :value # "\w" | "\W" | "\d" | "\D"

      def initialize(value)
        @value = value
      end

      def to_dot(parent)
        parent.add_node(object_id, label: value, shape: "box")
      end

      def to_nfa(start, finish)
        case value
        when "\\w"
          start.add_transition(NFA::Transition::Range.new(finish, "a", "z"))
          start.add_transition(NFA::Transition::Range.new(finish, "A", "Z"))
          start.add_transition(NFA::Transition::Range.new(finish, "0", "9"))
          start.add_transition(NFA::Transition::Set.new(finish, ["_"]))
        when "\\W"
          transition =
            NFA::Transition::Set.new(finish, [*("a".."z"), *("A".."Z"), *("0".."9"), "_"], invert: true)

          start.add_transition(transition)
        when "\\d"
          start.add_transition(NFA::Transition::Range.new(finish, "0", "9"))
        when "\\D"
          start.add_transition(NFA::Transition::Range.new(finish, "0", "9", invert: true))
        else
          raise
        end
      end
    end

    class Character
      attr_reader :value # String

      def initialize(value)
        @value = value
      end

      def to_dot(parent)
        parent.add_node(object_id, label: value, shape: "box")
      end

      def to_nfa_values
        [value]
      end

      def to_nfa(start, finish)
        transition = NFA::Transition::Set.new(finish, to_nfa_values)
        start.add_transition(transition)
      end
    end

    class Period
      def to_dot(parent)
        parent.add_node(object_id, label: ".", shape: "box")
      end

      def to_nfa(start, finish)
        transition = NFA::Transition::Any.new(finish)
        start.add_transition(transition)
      end
    end

    class CharacterRange
      attr_reader :left, :right # String

      def initialize(left, right)
        @left = left
        @right = right
      end

      def to_dot(parent)
        parent.add_node(object_id, label: "#{left}-#{right}", shape: "box")
      end

      def to_nfa_values
        (left..right).to_a
      end

      def to_nfa(start, finish)
        transition = NFA::Transition::Range.new(finish, left, right)
        start.add_transition(transition)
      end
    end

    class Anchor
      attr_reader :value # "\A" | "\z" | "$"

      def initialize(value)
        @value = value
      end

      def to_dot(parent)
        parent.add_node(object_id, label: value, shape: "box")
      end

      def to_nfa(start, finish)
        transition =
          case value
          when "\\A"
            NFA::Transition::BeginAnchor.new(finish)
          when "\\z"
            NFA::Transition::EndAnchor.new(finish)
          when "$"
            NFA::Transition::EndAnchor.new(finish)
          end

        start.add_transition(transition)
      end
    end

    module Quantifier
      class Once
        def to_dot(parent)
        end

        def quantify(start, finish)
          yield start, finish
        end
      end

      class ZeroOrMore
        def to_dot(parent)
          parent.add_node(object_id, label: "*", shape: "box")
        end

        def quantify(start, finish)
          yield start, start
          start.add_transition(NFA::Transition::Epsilon.new(finish))
        end
      end

      class OneOrMore
        def to_dot(parent)
          parent.add_node(object_id, label: "+", shape: "box")
        end
      
        def quantify(start, finish)
          yield start, finish
          finish.add_transition(NFA::Transition::Epsilon.new(start))
        end
      end

      class Optional
        def to_dot(parent)
          parent.add_node(object_id, label: "?", shape: "box")
        end

        def quantify(start, finish)
          yield start, finish
          start.add_transition(NFA::Transition::Epsilon.new(finish))
        end
      end

      class Exact
        attr_reader :value # Integer

        def initialize(value)
          @value = value
        end

        def to_dot(parent)
          parent.add_node(object_id, label: "{#{value}}", shape: "box")
        end

        def quantify(start, finish)
          states = [start, *(value - 1).times.map { NFA::State.new }, finish]

          value.times do |index|
            yield states[index], states[index + 1]
          end
        end
      end

      class AtLeast
        attr_reader :value # Integer

        def initialize(value)
          @value = value
        end

        def to_dot(parent)
          parent.add_node(object_id, label: "{#{value},}", shape: "box")
        end

        def quantify(start, finish)
          states = [start, *(value - 1).times.map { NFA::State.new }, finish]

          value.times do |index|
            yield states[index], states[index + 1]
          end

          states[-1].add_transition(NFA::Transition::Epsilon.new(states[-2]))
        end
      end

      class Range
        attr_reader :lower, :upper # Integer

        def initialize(lower, upper)
          @lower = lower
          @upper = upper
        end

        def to_dot(parent)
          parent.add_node(object_id, label: "{#{lower},#{upper}}", shape: "box")
        end

        def quantify(start, finish)
          states = [start, *(upper - 1).times.map { NFA::State.new }, finish]

          upper.times do |index|
            yield states[index], states[index + 1]
          end

          (upper - lower).times do |index|
            transition = NFA::Transition::Epsilon.new(states[-1])
            states[lower + index].add_transition(transition)
          end
        end
      end
    end
  end
end
