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
      # Expression[]
      attr_reader :expressions

      # bool
      attr_reader :at_start

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

      def to_nfa(optimize: true)
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

        Optimize.optimize(start) if optimize
        start
      end
    end

    class Expression
      # Group | Match | Anchor
      attr_reader :items

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
      # Expression[]
      attr_reader :expressions

      # Quantifier?
      attr_reader :quantifier

      def initialize(expressions, quantifier: nil)
        @expressions = expressions
        @quantifier = quantifier
      end

      def to_dot(parent)
        node = parent.add_node(object_id, label: "Group")

        expressions.each { |expression| expression.to_dot(node) }
        quantifier.to_dot(node) if quantifier
      end

      def to_nfa_once(start, finish)
        expressions.each { |expression| expression.to_nfa(start, finish) }
      end

      def to_nfa(start, finish)
        if quantifier
          quantifier.to_nfa(self, start, finish)
        else
          to_nfa_once(start, finish)
        end
      end
    end

    class Match
      # CharacterGroup | CharacterClass | Character | Period
      attr_reader :item

      # Quantifier?
      attr_reader :quantifier

      def initialize(item, quantifier: nil)
        @item = item
        @quantifier = quantifier
      end

      def to_dot(parent)
        node = parent.add_node(object_id, label: "Match")

        item.to_dot(node)
        quantifier.to_dot(node) if quantifier
      end

      def to_nfa_once(start, finish)
        item.to_nfa(start, finish)
      end

      def to_nfa(start, finish)
        if quantifier
          quantifier.to_nfa(self, start, finish)
        else
          to_nfa_once(start, finish)
        end
      end
    end

    class CharacterGroup
      # (CharacterRange | Character)[]
      attr_reader :items

      # bool
      attr_reader :invert

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
      # "\w" | "\W" | "\d" | "\D"
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def to_dot(parent)
        parent.add_node(object_id, label: value, shape: "box")
      end

      def to_nfa(start, finish)
        transition =
          case value
          when "\\w"
            NFA::Transition::Set.new(
              finish,
              [*("a".."z"), *("A".."Z"), *("0".."9"), "_"]
            )
          when "\\W"
            NFA::Transition::Set.new(
              finish,
              [*("a".."z"), *("A".."Z"), *("0".."9"), "_"],
              invert: true
            )
          when "\\d"
            NFA::Transition::Set.new(finish, ("0".."9").to_a)
          when "\\D"
            NFA::Transition::Set.new(finish, ("0".."9").to_a, invert: true)
          end

        start.add_transition(transition)
      end
    end

    class Character
      # string
      attr_reader :value

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
      # string
      attr_reader :left, :right

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
        transition = NFA::Transition::Set.new(finish, to_nfa_values)
        start.add_transition(transition)
      end
    end

    class Anchor
      # "\A" | "\z" | "$"
      attr_reader :value

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
      class ZeroOrMore
        def to_dot(parent)
          parent.add_node(object_id, label: "*", shape: "box")
        end

        def to_nfa(node, start, finish)
          node.to_nfa_once(start, finish)
          start.add_transition(NFA::Transition::Epsilon.new(finish))
          finish.add_transition(NFA::Transition::Epsilon.new(start))
        end
      end

      class OneOrMore
        def to_dot(parent)
          parent.add_node(object_id, label: "+", shape: "box")
        end
      
        def to_nfa(node, start, finish)
          node.to_nfa_once(start, finish)
          finish.add_transition(NFA::Transition::Epsilon.new(start))
        end
      end

      class Optional
        def to_dot(parent)
          parent.add_node(object_id, label: "?", shape: "box")
        end

        def to_nfa(node, start, finish)
          node.to_nfa_once(start, finish)
          start.add_transition(NFA::Transition::Epsilon.new(finish))
        end
      end

      class Exact
        # Integer
        attr_reader :value

        def initialize(value)
          @value = value
        end

        def to_dot(parent)
          parent.add_node(object_id, label: "{#{value}}", shape: "box")
        end

        def to_nfa(node, start, finish)
          states = [start, *(value - 1).times.map { NFA::State.new }, finish]

          value.times do |index|
            node.to_nfa_once(states[index], states[index + 1])
          end
        end
      end

      class AtLeast
        # Integer
        attr_reader :value

        def initialize(value)
          @value = value
        end

        def to_dot(parent)
          parent.add_node(object_id, label: "{#{value},}", shape: "box")
        end

        def to_nfa(node, start, finish)
          states = [start, *(value - 1).times.map { NFA::State.new }, finish]

          value.times do |index|
            node.to_nfa_once(states[index], states[index + 1])
          end

          states[-1].add_transition(NFA::Transition::Epsilon.new(states[-2]))
        end
      end

      class Range
        # Integer
        attr_reader :lower, :upper

        def initialize(lower, upper)
          @lower = lower
          @upper = upper
        end

        def to_dot(parent)
          parent.add_node(object_id, label: "{#{lower},#{upper}}", shape: "box")
        end

        def to_nfa(node, start, finish)
          states = [start, *(upper - 1).times.map { NFA::State.new }, finish]

          upper.times do |index|
            node.to_nfa_once(states[index], states[index + 1])
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
