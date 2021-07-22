# frozen_string_literal: true

module RegularExpression
  module NFA
    class << self
      def to_dot(nfa, filename: "nfa")
        graph = Graphviz::Graph.new(rankdir: "LR")
        nfa.to_dot(graph, {})

        Graphviz.output(graph, path: "build/#{filename}.svg", format: "svg")
        graph.to_dot
      end

      # Using a queue, walk through the AST and build up a state machine.
      def build(root, flags)
        response = StartState.new
        worklist = [[root, response, FinishState.new]]

        labels = ("1"..).each
        captures = (0..).each

        while worklist.any?
          node, start_state, finish_state = worklist.shift

          case node
          when AST::Root
            capture_index = captures.next

            match_start = State.new(labels.next)
            start_state.unshift(Transition::StartCapture.new(match_start, capture_index))

            match_finish = State.new(+"") # replaced below
            match_finish.unshift(Transition::EndCapture.new(finish_state, capture_index))

            current = match_start

            if node.at_start
              current = State.new(labels.next)
              match_start.unshift(Transition::BeginAnchor.new(current))
            end

            node.expressions.each do |expression|
              worklist.push([expression, current, match_finish])
            end
          when AST::Expression
            inner_states = Array.new(node.items.length - 1) { State.new(labels.next) }
            node_states = [start_state, *inner_states, finish_state]

            node.items.each_with_index do |item, index|
              worklist.push([item, node_states[index], node_states[index + 1]])
            end
          when AST::Group
            quantify(node.quantifier, start_state, finish_state, labels) do |quantified_start, quantified_finish|
              node.expressions.each do |expression|
                worklist.push([expression, quantified_start, quantified_finish])
              end
            end
          when AST::CaptureGroup
            quantify(node.quantifier, start_state, finish_state, labels) do |quantified_start, quantified_finish|
              capture_index = captures.next

              capture_start = State.new(labels.next)
              quantified_start.unshift(Transition::StartCapture.new(capture_start, capture_index, node.name))

              capture_finish = State.new(labels.next)
              capture_finish.unshift(Transition::EndCapture.new(quantified_finish, capture_index))

              node.expressions.each do |expression|
                worklist.push([expression, capture_start, capture_finish])
              end
            end
          when AST::Match
            quantify(node.quantifier, start_state, finish_state, labels) do |quantified_start, quantified_finish|
              worklist.push([node.item, quantified_start, quantified_finish])
            end
          when AST::CharacterGroup
            if node.invert
              transition = Transition::Invert.new(finish_state, node.items.flat_map(&:to_nfa_values).sort, ignore_case: flags.ignore_case?)
              start_state.unshift(transition)
            else
              node.items.each { |item| worklist.push([item, start_state, finish_state]) }
            end
          when AST::CharacterClass
            case node.value
            when %q{\w}
              start_state.unshift(Transition::Range.new(finish_state, "a", "z", ignore_case: flags.ignore_case?))
              start_state.unshift(Transition::Range.new(finish_state, "A", "Z", ignore_case: flags.ignore_case?))
              start_state.unshift(Transition::Range.new(finish_state, "0", "9"))
              start_state.unshift(Transition::Value.new(finish_state, "_"))
            when %q{\W}
              start_state.unshift(Transition::Invert.new(finish_state, [*("a".."z"), *("A".."Z"), *("0".."9"), "_"], ignore_case: flags.ignore_case?))
            when %q{\d}
              start_state.unshift(Transition::Range.new(finish_state, "0", "9"))
            when %q{\D}
              start_state.unshift(Transition::Range.new(finish_state, "0", "9", invert: true))
            when %q{\h}
              start_state.unshift(Transition::Range.new(finish_state, "a", "f", ignore_case: flags.ignore_case?))
              start_state.unshift(Transition::Range.new(finish_state, "A", "F", ignore_case: flags.ignore_case?))
              start_state.unshift(Transition::Range.new(finish_state, "0", "9"))
            when %q{\H}
              start_state.unshift(Transition::Invert.new(finish_state, [*("a".."h"), *("A".."H"), *("0".."9")], ignore_case: flags.ignore_case?))
            when %q{\s}
              start_state.unshift(Transition::Value.new(finish_state, " "))
              start_state.unshift(Transition::Value.new(finish_state, "\t"))
              start_state.unshift(Transition::Value.new(finish_state, "\r"))
              start_state.unshift(Transition::Value.new(finish_state, "\n"))
              start_state.unshift(Transition::Value.new(finish_state, "\f"))
              start_state.unshift(Transition::Value.new(finish_state, "\v"))
            when %q{\S}
              start_state.unshift(Transition::Invert.new(finish_state, [" ", "\t", "\r", "\n", "\f", "\v"]))
            else
              raise
            end
          when AST::CharacterType
            start_state.unshift(Transition::Type.new(finish_state, node.value))
          when AST::Character
            start_state.unshift(Transition::Value.new(finish_state, node.value, ignore_case: flags.ignore_case?))
          when AST::Period
            start_state.unshift(Transition::Any.new(finish_state))
          when AST::PositiveLookahead
            start_state.unshift(Transition::PositiveLookahead.new(finish_state, node.value))
          when AST::NegativeLookahead
            start_state.unshift(Transition::NegativeLookahead.new(finish_state, node.value))
          when AST::CharacterRange
            start_state.unshift(Transition::Range.new(finish_state, node.left, node.right, ignore_case: flags.ignore_case?))
          when AST::Anchor
            transition =
              case node.value
              when %q{\A}
                Transition::BeginAnchor.new(finish_state)
              when %q{\z}, %q{$}
                Transition::EndAnchor.new(finish_state)
              end

            start_state.unshift(transition)
          else
            raise
          end
        end

        match_finish.label.replace(labels.next)
        response
      end

      private

      def quantify(quantifier, start_state, finish_state, labels)
        case quantifier
        when AST::Quantifier::Once
          yield start_state, finish_state
        when AST::Quantifier::ZeroOrMore
          yield start_state, start_state
          start_state.push(Transition::Epsilon.new(finish_state))
        when AST::Quantifier::OneOrMore
          yield start_state, finish_state
          finish_state.push(Transition::Epsilon.new(start_state))
        when AST::Quantifier::Optional
          yield start_state, finish_state
          start_state.push(Transition::Epsilon.new(finish_state))
        when AST::Quantifier::Exact
          states = [start_state, *(quantifier.value - 1).times.map { State.new(labels.next) }, finish_state]

          quantifier.value.times do |index|
            yield states[index], states[index + 1]
          end
        when AST::Quantifier::AtLeast
          states = [start_state, *(quantifier.value - 1).times.map { State.new(labels.next) }, finish_state]

          quantifier.value.times do |index|
            yield states[index], states[index + 1]
          end

          states[-1].push(Transition::Epsilon.new(states[-2]))
        when AST::Quantifier::Range
          states = [start_state, *(quantifier.upper - 1).times.map { State.new(labels.next) }, finish_state]

          quantifier.upper.times do |index|
            yield states[index], states[index + 1]
          end

          (quantifier.upper - quantifier.lower).times do |index|
            states[quantifier.lower + index].push(Transition::Epsilon.new(states[-1]))
          end
        else
          raise
        end
      end

      def char_in_other_case(char)
        if char != (downcase = char.downcase)
          downcase
        elsif char != (upcase = char.upcase)
          upcase
        end
      end
    end

    class State
      attr_reader :label # String
      attr_reader :transitions # Array[Transition]

      def initialize(label = "")
        @label = label
        @transitions = []
      end

      def unshift(transition)
        transitions.unshift(transition)
      end

      def push(transition)
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
      def initialize(label = "Start")
        super
      end

      def to_dot(graph, visited)
        super(graph, visited).tap do |node|
          node.attributes.merge!(shape: "box")
        end
      end
    end

    class FinishState < State
      def initialize(label = "Finish")
        super
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

      class StartCapture < Struct.new(:state, :index, :name)
        def label
          "Start capture #{name || index}"
        end

        def matches?(other)
          other.is_a?(StartCapture) && index == other.index
        end

        def copy(new_state)
          StartCapture.new(new_state, index)
        end
      end

      class EndCapture < Struct.new(:state, :index)
        def label
          "End capture #{index}"
        end

        def matches?(other)
          other.is_a?(EndCapture) && index == other.index
        end

        def copy(new_state)
          EndCapture.new(new_state, index)
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

      class Value
        attr_reader :state # State
        attr_reader :value # String
        attr_reader :ignore_case # bool

        def initialize(state, value, ignore_case: false)
          @state = state
          @value = value
          @ignore_case = ignore_case
        end

        def label
          IgnoreCase.label(value.inspect, ignore_case)
        end

        def matches?(other)
          case other
          when Any
            true
          when Value
            IgnoreCase.matches?(value, ignore_case) do |value|
              value == other.value
            end
          when Invert
            IgnoreCase.matches?(value, ignore_case) do |value|
              !other.values.include?(value)
            end
          when Range
            IgnoreCase.matches?(value, ignore_case) do |value|
              matches = value >= other.left && value <= other.right
              matches = !matched if other.invert
              matches
            end
          else
            false
          end
        end

        def copy(new_state)
          Value.new(new_state, value, ignore_case: ignore_case)
        end
      end

      class Type < Struct.new(:state, :type)
        # @TODO does it make sense to add ignore case to these character class?
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
        attr_reader :ignore_case # bool

        def initialize(state, values, ignore_case: false)
          @state = state
          @values = values
          @ignore_case = ignore_case
        end

        def label
          IgnoreCase.label(%Q{[^#{values.join}]}, ignore_case)
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
        attr_reader :ignore_case # bool

        def initialize(state, left, right, invert: false, ignore_case: false)
          @state = state
          @left = left
          @right = right
          @invert = invert
          @ignore_case = ignore_case
        end

        def label
          IgnoreCase.label(%Q{#{left}-#{right}}, ignore_case)
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
          Range.new(new_state, left, right, invert: invert, ignore_case: ignore_case)
        end
      end

      class PositiveLookahead < Struct.new(:state, :value, :ignore_case)
        def label
          IgnoreCase.label("(?=#{value})", ignore_case)
        end

        def matches?(other)
          other.is_a?(PositiveLookahead) && value == other.value
        end

        def copy(new_state)
          PositiveLookahead.new(new_state, value)
        end
      end

      class NegativeLookahead < Struct.new(:state, :value, :ignore_case)
        def label
          IgnoreCase.label("(?!#{value})", ignore_case)
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
