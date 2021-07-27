# frozen_string_literal: true

module RegularExpression
  module AST
    def self.to_dot(root)
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
    end

    class Expression
      attr_reader :items # Group | CaptureGroup | Match | Anchor

      def initialize(items)
        @items = items
      end

      def to_dot(parent)
        node = parent.add_node(object_id, label: "Expression")

        items.each { |item| item.to_dot(node) }
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
    end

    class CaptureGroup
      attr_reader :expressions # Array[Expression]
      attr_reader :quantifier # Quantifier
      attr_reader :name # untyped

      def initialize(expressions, quantifier: Quantifier::Once.new, name: nil)
        @expressions = expressions
        @quantifier = quantifier
        @name = name
      end

      def to_dot(parent)
        node = parent.add_node(object_id, label: "CaptureGroup")

        expressions.each { |expression| expression.to_dot(node) }
        quantifier.to_dot(node)
      end
    end

    class Match
      attr_reader :item # CharacterGroup | CharacterClass | Character | Period | PositiveLookahead | NegativeLookahead
      attr_reader :quantifier # Quantifier

      def initialize(item, quantifier: Quantifier::Once.new)
        @item = item
        @quantifier = quantifier
      end

      def to_dot(parent)
        node = parent.add_node(object_id, label: "Match")

        item.to_dot(node)
        quantifier.to_dot(node)
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
    end

    class CharacterClass
      attr_reader :value # "\w" | "\W" | "\d" | "\D" | "\h" | "\H" | "\s" | "\S"

      def initialize(value)
        @value = value
      end

      def to_dot(parent)
        parent.add_node(object_id, label: value, shape: "box")
      end
    end

    class CharacterType
      attr_reader :value # "alnum" | "alpha" | "lower" | "upper"

      def initialize(value)
        @value = value
      end

      def to_dot(parent)
        parent.add_node(object_id, label: "[[:#{value}:]]", shape: "box")
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
    end

    class Period
      def to_dot(parent)
        parent.add_node(object_id, label: ".", shape: "box")
      end
    end

    class PositiveLookahead
      attr_reader :values # Array[Character]

      def initialize(values)
        @values = values
      end

      def value
        values.map(&:value).join
      end

      def to_dot(parent)
        parent.add_node(object_id, label: "(?=#{value})", shape: "box")
      end
    end

    class NegativeLookahead
      attr_reader :values # Array[Character]

      def initialize(values)
        @values = values
      end

      def value
        values.map(&:value).join
      end

      def to_dot(parent)
        parent.add_node(object_id, label: "(?!#{value})", shape: "box")
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
    end

    class Anchor
      attr_reader :value # "\A" | "\z" | "$"

      def initialize(value)
        @value = value
      end

      def to_dot(parent)
        parent.add_node(object_id, label: value, shape: "box")
      end
    end

    module Quantifier
      class Once
        def to_dot(parent); end
      end

      class ZeroOrMore
        def to_dot(parent)
          parent.add_node(object_id, label: "*", shape: "box")
        end
      end

      class OneOrMore
        def to_dot(parent)
          parent.add_node(object_id, label: "+", shape: "box")
        end
      end

      class Optional
        def to_dot(parent)
          parent.add_node(object_id, label: "?", shape: "box")
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
      end

      class AtLeast
        attr_reader :value # Integer

        def initialize(value)
          @value = value
        end

        def to_dot(parent)
          parent.add_node(object_id, label: "{#{value},}", shape: "box")
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
      end
    end
  end
end
