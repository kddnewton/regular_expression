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
      # Transition[]
      attr_reader :transitions

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

      def accept(string, index)
        transitions.detect do |transition|
          accepted = transition.accept(string, index)
          break accepted if accepted
        end
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

      def accept(string, index)
        self
      end
    end

    module Transition
      class BeginAnchor
        # State
        attr_reader :state

        def initialize(state)
          @state = state
        end

        def label
          "\\A"
        end

        def accept(string, index)
          state.accept(string, index) if index == 0
        end
      end

      class EndAnchor
        # State
        attr_reader :state

        def initialize(state)
          @state = state
        end

        def label
          "\\z"
        end

        def accept(string, index)
          state.accept(string, index) if index == string.length
        end
      end

      class Any
        # State
        attr_reader :state

        def initialize(state)
          @state = state
        end

        def label
          "."
        end

        def accept(string, index)
          state.accept(state, index + 1) if index < string.length
        end
      end

      class Set
        # State
        attr_reader :state

        # string[]
        attr_reader :values

        # bool
        attr_reader :invert

        def initialize(state, values, invert: false)
          @state = state
          @values = values
          @invert = invert
        end

        def label
          values.inspect
        end

        def accept(string, index)
          accepted = values.any? { |value| string[index..].start_with?(value) }
          accepted = !accepted if invert

          state.accept(string, index + 1) if accepted
        end
      end

      class Epsilon
        # State
        attr_reader :state

        def initialize(state)
          @state = state
        end

        def label
          "ε"
        end

        def accept(string, index)
          state.accept(string, index)
        end
      end
    end
  end
end
