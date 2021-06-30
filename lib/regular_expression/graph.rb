# frozen_string_literal: true

module RegularExpression
  module AST
    class Root
      def to_graph
        require "graphviz"

        graph = Graphviz::Graph.new

        label = "Root"
        label = "#{label} (at start)" if at_start

        node = graph.add_node(object_id, label: label)
        expressions.each { |expression| expression.to_graph(node) }

        Graphviz.output(graph, path: "graph.svg", format: "svg")
        graph.to_dot
      end
    end

    class Expression
      def to_graph(parent)
        node = parent.add_node(object_id, label: "Expression")

        items.each { |item| item.to_graph(node) }
      end
    end

    class Group
      def to_graph(parent)
        label = "Group (#{capture ? "capture" : "no capture"})"
        node = parent.add_node(object_id, label: label)

        expressions.each { |expression| expression.to_graph(node) }
        quantifier.to_graph(node) if quantifier
      end
    end

    class Match
      def to_graph(parent)
        node = parent.add_node(object_id, label: "Match")

        item.to_graph(node)
        quantifier.to_graph(node) if quantifier
      end
    end

    class CharacterGroup
      def to_graph(parent)
        label = "CharacterGroup"
        label = "#{label} (invert)" if invert

        node = parent.add_node(object_id, label: label)
        items.each { |item| item.to_graph(node) }
      end
    end

    class CharacterClass
      def to_graph(parent)
        parent.add_node(object_id, label: value, shape: "box")
      end
    end

    class Character
      def to_graph(parent)
        parent.add_node(object_id, label: value, shape: "box")
      end
    end

    class Period
      def to_graph(parent)
        parent.add_node(object_id, label: ".", shape: "box")
      end
    end

    class CharacterRange
      def to_graph(parent)
        parent.add_node(object_id, label: "#{left}-#{right}", shape: "box")
      end
    end

    class Anchor
      def to_graph(parent)
        parent.add_node(object_id, label: value, shape: "box")
      end
    end

    class Quantifier
      class ZeroOrMore
        def to_graph(parent)
          parent.add_node(object_id, label: "*", shape: "box")
        end
      end

      class OneOrMore
        def to_graph(parent)
          parent.add_node(object_id, label: "+", shape: "box")
        end
      end

      class Optional
        def to_graph(parent)
          parent.add_node(object_id, label: "?", shape: "box")
        end
      end

      class Exact
        def to_graph(parent)
          parent.add_node(object_id, label: "{#{value}}", shape: "box")
        end
      end

      class AtLeast
        def to_graph(parent)
          parent.add_node(object_id, label: "{#{value},}", shape: "box")
        end
      end

      class Range
        def to_graph(parent)
          parent.add_node(object_id, label: "{#{lower},#{upper}}", shape: "box")
        end
      end

      def to_graph(parent)
        label = "Quantifier"
        label = "#{label} (greedy)" if greedy

        node = parent.add_node(object_id, label: label)
        type.to_graph(node)
      end
    end
  end
end
