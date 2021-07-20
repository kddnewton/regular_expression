# frozen_string_literal: true

module RegularExpression
  module NFA
    def self.to_dot(nfa, filename: "nfa")
      graph = Graphviz::Graph.new(rankdir: "LR")
      nfa.to_dot(graph, {})

      Graphviz.output(graph, path: "build/#{filename}.svg", format: "svg")
      graph.to_dot
    end

    class State
      attr_reader :label # String
      attr_reader :transitions # Array[Transition]

      def initialize(label = "")
        @label = label
        @transitions = []
      end

      def add_transition(transition)
        transitions << transition
      end

      def to_dot(graph, visited)
        return visited[self] if visited.include?(self)

        source = graph.add_node(object_id, label: label)
        visited[self] = source

        transitions.each do |transition|
          target = transition.state.to_dot(graph, visited)
          source.connect(target, label: transition.label)
        end

        source
      end
    end

    class StartState < State
      def label
        "Start"
      end

      def to_dot(graph, visited)
        super(graph, visited).tap do |node|
          node.attributes.merge!(shape: "box")
        end
      end
    end

    class FinishState < State
      def label
        "Finish"
      end

      def to_dot(graph, visited)
        super(graph, visited).tap do |node|
          node.attributes.merge!(shape: "box")
        end
      end
    end

    module Transition
      class BeginAnchor < Struct.new(:state)
        def label
          %q{\A}
        end

        def matches?(other)
          other.is_a?(BeginAnchor)
        end

        def copy(new_state)
          BeginAnchor.new(new_state)
        end
      end

      class EndAnchor < Struct.new(:state)
        def label
          %q{\z}
        end

        def matches?(other)
          other.is_a?(EndAnchor)
        end

        def copy(new_state)
          EndAnchor.new(new_state)
        end
      end

      class StartCapture < Struct.new(:state, :name)
        def label
          "Start capture #{name}"
        end

        def matches?(other)
          other.is_a?(StartCapture) && name == other.name
        end

        def copy(new_state)
          StartCapture.new(new_state, name)
        end
      end

      class EndCapture < Struct.new(:state, :name)
        def label
          "End capture #{name}"
        end

        def matches?(other)
          other.is_a?(EndCapture) && name == other.name
        end

        def copy(new_state)
          EndCapture.new(new_state, name)
        end
      end

      class Any < Struct.new(:state)
        def label
          %q{.}
        end

        def matches?(other)
          case other
          when Any, Value, Invert, Range
            true
          else
            false
          end
        end

        def copy(new_state)
          Any.new(new_state)
        end
      end

      class Value < Struct.new(:state, :value)
        def label
          value.inspect
        end

        def matches?(other)
          case other
          when Any
            true
          when Value
            value == other.value
          when Invert
            !other.values.include?(value)
          when Range
            matches = value >= other.left && value <= other.right
            matches = !matched if other.invert
            matches
          else
            false
          end
        end

        def copy(new_state)
          Value.new(new_state, value)
        end
      end

      class Type < Struct.new(:state, :type)
        def label
          "[[:#{type}:]]"
        end

        def matches?(other)
          other.is_a?(Type) && type == other.type
        end

        def copy(new_state)
          Type.new(new_state, type)
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
          %Q{[^#{values.join}]}
        end

        def matches?(other)
          case other
          when Any
            true
          when Value
            !values.include?(other.value)
          when Invert
            values == other.values
          when Range
            raise NotImplemented
          else
            false
          end
        end

        def copy(new_state)
          Invert.new(new_state, values)
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
          %Q{#{left}-#{right}}
        end

        def matches?(other)
          case other
          when Any
            true
          when Value
            matches = other.value >= left && other.value <= right
            matches = !matches if invert
            matches
          when Invert
            raise NotImplemented
          when Range
            left == other.left && right == other.right && invert == other.invert
          else
            false
          end
        end

        def copy(new_state)
          Range.new(new_state, left, right, invert: invert)
        end
      end

      class PositiveLookahead < Struct.new(:state, :value)
        def label
          "(?=#{value})"
        end

        def matches?(other)
          other.is_a?(PositiveLookahead) && value == other.value
        end

        def copy(new_state)
          PositiveLookahead.new(new_state, value)
        end
      end

      class NegativeLookahead < Struct.new(:state, :value)
        def label
          "(?!#{value})"
        end

        def matches?(other)
          other.is_a?(NegativeLookahead) && value == other.value
        end

        def copy(new_state)
          NegativeLookahead.new(new_state, value)
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
