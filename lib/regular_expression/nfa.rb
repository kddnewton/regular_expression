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
      class BeginAnchor
        attr_reader :state # State

        def initialize(state)
          @state = state
        end

        def label
          "\\A"
        end
      end

      class EndAnchor
        attr_reader :state # State

        def initialize(state)
          @state = state
        end

        def label
          "\\z"
        end
      end

      class Any
        attr_reader :state # State

        def initialize(state)
          @state = state
        end

        def label
          "."
        end
      end

      class Set
        attr_reader :state # State
        attr_reader :values # Array[String]
        attr_reader :invert # bool

        def initialize(state, values, invert: false)
          @state = state
          @values = values
          @invert = invert
        end

        def label
          values.inspect
        end
      end

      class Epsilon
        attr_reader :state # State

        def initialize(state)
          @state = state
        end

        def label
          "ε"
        end
      end
    end
  end
end
