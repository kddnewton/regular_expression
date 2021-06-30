# frozen_string_literal: true

module RegularExpression
  module NFA
    def self.to_dot(nfa)
      require "graphviz"
      graph = Graphviz::Graph.new(rankdir: "LR")
      nfa.to_dot(graph)
    
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

      def to_dot(graph)
        source = graph.add_node(object_id, label: "")

        transitions.each do |transition|
          target = transition.state.to_dot(graph)
          source.connect(target, label: transition.label)
        end

        source
      end
    end

    class StartState < State
      def to_dot(graph)
        super(graph).tap do |node|
          node.attributes.merge!(label: "Start", shape: "box")
        end
      end
    end

    class FinishState < State
      def to_dot(graph)
        super(graph).tap do |node|
          node.attributes.merge!(label: "Finish", shape: "box")
        end
      end
    end

    class Transition
      class Anchor
        # State
        attr_reader :state

        # string
        attr_reader :value

        def initialize(state, value)
          @state = state
          @value = value
        end

        alias label value
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
      end

      class Character
        # State
        attr_reader :state

        # string
        attr_reader :value

        def initialize(state, value)
          @state = state
          @value = value
        end

        alias label value
      end

      class CharacterClass
        # State
        attr_reader :state

        # string
        attr_reader :value

        def initialize(state, value)
          @state = state
          @value = value
        end

        alias label value
      end

      class CharacterGroup
        # State
        attr_reader :state

        # (CharacterRange | Character)[]
        attr_reader :transitions

        # bool
        attr_reader :invert

        def initialize(state, transitions, invert)
          @state = state
          @transitions = transitions
          @invert = invert
        end

        def label
          "[#{transitions.map(&:label).join}]"
        end
      end

      class CharacterRange
        # State
        attr_reader :state

        # string
        attr_reader :left, :right

        def initialize(state, left, right)
          @state = state
          @left = left
          @right = right
        end

        def label
          "#{left}-#{right}"
        end
      end
    end
  end
end
