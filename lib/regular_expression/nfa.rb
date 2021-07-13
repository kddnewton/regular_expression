# frozen_string_literal: true

module RegularExpression
  module NFA
    def self.to_dot(nfa)
      require "graphviz"

      graph = Graphviz::Graph.new(rankdir: "LR")
      nfa.to_dot(graph, {})
    
      Graphviz.output(graph, path: "build/nfa.svg", format: "svg")
      graph.to_dot
    end

    class State
      attr_reader :transitions # Array[Transition]

      def initialize
        @transitions = []
      end

      def add_transition(transition)
        transitions << transition
      end

      def to_dot(graph, visited)
        return visited[self] if visited.include?(self)

        source = graph.add_node(object_id, label: "")
        visited[self] = source

        transitions.each do |transition|
          target = transition.state.to_dot(graph, visited)
          source.connect(target, label: transition.label)
        end

        source
      end
    end

    class StartState < State
      def to_dot(graph, visited)
        super(graph, visited).tap do |node|
          node.attributes.merge!(label: "Start", shape: "box")
        end
      end
    end

    class FinishState < State
      def to_dot(graph, visited)
        super(graph, visited).tap do |node|
          node.attributes.merge!(label: "Finish", shape: "box")
        end
      end
    end

    module Transition
      class BeginAnchor < Struct.new(:state)
        def label
          "\\A"
        end
      end

      class EndAnchor < Struct.new(:state)
        def label
          "\\z"
        end
      end

      class Any < Struct.new(:state)
        def label
          "."
        end
      end

      class Value < Struct.new(:state, :value)
        def label
          value.inspect
        end
      end

      class Invert
        attr_reader :state # State
        attr_reader :values # Array[String]

        def initialize(state, values)
          @state = state
          @values = values
        end

        def label
          "[^#{values.join}]"
        end
      end

      class Range
        attr_reader :state # State
        attr_reader :left, :right # String
        attr_reader :invert # bool

        def initialize(state, left, right, invert: false)
          @state = state
          @left = left
          @right = right
          @invert = invert
        end

        def label
          "#{left}-#{right}"
        end
      end

      class Epsilon < Struct.new(:state)
        def label
          "ε"
        end
      end
    end
  end
end
