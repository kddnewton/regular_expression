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

      def to_nfa
        start = NFA::StartState.new
        finish = NFA::FinishState.new

        expressions.each do |expression|
          expression.to_nfa(start, finish)
        end

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
    
      # bool
      attr_reader :capture

      def initialize(expressions, quantifier: nil, capture: true)
        @expressions = expressions
        @quantifier = quantifier
        @capture = capture
      end

      def to_dot(parent)
        label = "Group (#{capture ? "capture" : "no capture"})"
        node = parent.add_node(object_id, label: label)

        expressions.each { |expression| expression.to_dot(node) }
        quantifier.to_dot(node) if quantifier
      end

      def to_nfa(start, finish)
        # TODO: capture
        expressions.each { |expression| expression.to_nfa(start, finish) }
        quantifier.to_nfa(start, finish) if quantifier
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

      def to_nfa(start, finish)
        item.to_nfa(start, finish)
        quantifier.to_nfa(start, finish) if quantifier
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
        transitions = items.map { |item| item.to_nfa_transition(finish) }
        transition = NFA::Transition::CharacterGroup.new(finish, transitions, invert)
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
        transition = NFA::Transition::CharacterClass.new(finish, value)
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

      def to_nfa_transition(finish)
        NFA::Transition::Character.new(finish, value)
      end

      def to_nfa(start, finish)
        start.add_transition(to_nfa_transition(finish))
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

      def to_nfa_transition(finish)
        NFA::Transition::CharacterRange.new(finish, left, right)
      end

      def to_nfa(start, finish)
        start.add_transition(to_nfa_transition(finish))
      end
    end

    class Anchor
      # "\b" | "\B" | "\A" | "\z" | "\Z" | "\G" | "$"
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def to_dot(parent)
        parent.add_node(object_id, label: value, shape: "box")
      end

      def to_nfa(start, finish)
        transition = NFA::Transition::Anchor.new(finish, value)
        start.add_transition(transition)
      end
    end

    module Quantifier
      class ZeroOrMore
        def to_dot(parent)
          parent.add_node(object_id, label: "*", shape: "box")
        end

        def to_nfa(start, finish)
          start.add_transition(NFA::Transition::Epsilon.new(finish))
          finish.add_transition(NFA::Transition::Epsilon.new(start))
        end
      end

      class OneOrMore
        def to_dot(parent)
          parent.add_node(object_id, label: "+", shape: "box")
        end
      
        def to_nfa(start, finish)
          finish.add_transition(NFA::Transition::Epsilon.new(start))
        end
      end

      class Optional
        def to_dot(parent)
          parent.add_node(object_id, label: "?", shape: "box")
        end

        def to_nfa(start, finish)
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

        def to_nfa(start, finish)
          raise NotImplementedError
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

        def to_nfa(start, finish)
          raise NotImplementedError
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

        def to_nfa(start, finish)
          raise NotImplementedError
        end
      end
    end
  end
end
