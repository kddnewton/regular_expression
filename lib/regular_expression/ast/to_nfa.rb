# frozen_string_literal: true

module RegularExpression
  module AST
    class ToNFA
      class << self
        def build(root)
          new(root).build
        end

        private(:new)
      end

      def initialize(root)
        @labels = ("1"..).each
        @start_state = NFA::StartState.new
        match_start = NFA::State.new(@labels.next)
        @start_state.add_transition(NFA::Transition::StartCapture.new(match_start, "$0"))

        finish_state = NFA::FinishState.new
        @match_finish = NFA::State.new(+"")
        @match_finish.add_transition(NFA::Transition::EndCapture.new(finish_state, "$0"))

        current = match_start

        if root.at_start
          current = NFA::State.new(@labels.next)
          match_start.add_transition(NFA::Transition::BeginAnchor.new(current))
        end
        @worklist = []
        push_work(root.expressions.map { |ex| [ex, current, @match_finish] })
      end

      def build
        while (node, start, finish = pop_work)
          case node
          when Expression
            items = node.items
            inner = Array.new(items.length - 1) { NFA::State.new(@labels.next) }
            states = [start, *inner, finish]

            work = items.map.with_index do |item, index|
              [item, states[index], states[index + 1]]
            end
            push_work(work)
          when Group
            expressions = node.expressions
            quantifier = node.quantifier

            quantify(quantifier, start, finish) do |qstart, _qfinish, acc|
              expressions.each do |expression|
                acc << [expression, qstart, finish]
              end
            end
          when CaptureGroup
            expressions = node.expressions
            quantifier = node.quantifier
            name = node.name

            quantify(quantifier, start, finish) do |qstart, qfinish, acc|
              capture_start = NFA::State.new(@labels.next)
              qstart.add_transition(NFA::Transition::StartCapture.new(capture_start, name))

              capture_finish = NFA::State.new(@labels.next)
              capture_finish.add_transition(NFA::Transition::EndCapture.new(qfinish, name))

              expressions.each do |expression|
                acc << [expression, capture_start, capture_finish]
              end
            end
          when Match
            item = node.item
            quantifier = node.quantifier

            quantify(quantifier, start, finish) do |qstart, qfinish, acc|
              acc << [item, qstart, qfinish]
            end
          when CharacterGroup
            items = node.items

            if node.invert
              transition = NFA::Transition::Invert.new(finish, items.flat_map(&:to_nfa_values).sort)
              start.add_transition(transition)
            else
              work = items.map do |nitem|
                [nitem, start, finish]
              end
              push_work(work)
            end
          when CharacterClass
            case node.value
            when %q{\w}
              start.add_transition(NFA::Transition::Range.new(finish, "a", "z"))
              start.add_transition(NFA::Transition::Range.new(finish, "A", "Z"))
              start.add_transition(NFA::Transition::Range.new(finish, "0", "9"))
              start.add_transition(NFA::Transition::Value.new(finish, "_"))
            when %q{\W}
              start.add_transition(NFA::Transition::Invert.new(finish, [*("a".."z"), *("A".."Z"), *("0".."9"), "_"]))
            when %q{\d}
              start.add_transition(NFA::Transition::Range.new(finish, "0", "9"))
            when %q{\D}
              start.add_transition(NFA::Transition::Range.new(finish, "0", "9", invert: true))
            when %q{\h}
              start.add_transition(NFA::Transition::Range.new(finish, "a", "f"))
              start.add_transition(NFA::Transition::Range.new(finish, "A", "F"))
              start.add_transition(NFA::Transition::Range.new(finish, "0", "9"))
            when %q{\H}
              start.add_transition(NFA::Transition::Invert.new(finish, [*("a".."h"), *("A".."H"), *("0".."9")]))
            when %q{\s}
              start.add_transition(NFA::Transition::Value.new(finish, " "))
              start.add_transition(NFA::Transition::Value.new(finish, "\t"))
              start.add_transition(NFA::Transition::Value.new(finish, "\r"))
              start.add_transition(NFA::Transition::Value.new(finish, "\n"))
              start.add_transition(NFA::Transition::Value.new(finish, "\f"))
              start.add_transition(NFA::Transition::Value.new(finish, "\v"))
            when %q{\S}
              start.add_transition(NFA::Transition::Invert.new(finish, [" ", "\t", "\r", "\n", "\f", "\v"]))
            else
              raise
            end
          when CharacterType
            start.add_transition(NFA::Transition::Type.new(finish, node.value))
          when Character
            start.add_transition(NFA::Transition::Value.new(finish, node.value))
          when Period
            transition = NFA::Transition::Any.new(finish)
            start.add_transition(transition)
          when PositiveLookahead
            start.add_transition(NFA::Transition::PositiveLookahead.new(finish, node.value))
          when NegativeLookahead
            start.add_transition(NFA::Transition::NegativeLookahead.new(finish, node.value))
          when CharacterRange
            transition = NFA::Transition::Range.new(finish, node.left, node.right)
            start.add_transition(transition)
          when Anchor
            transition =
              case node.value
              when %q{\A}
                NFA::Transition::BeginAnchor.new(finish)
              when %q{\z}, %q{$}
                NFA::Transition::EndAnchor.new(finish)
              end

            start.add_transition(transition)
          when AddEpsilon
            start.add_transition(NFA::Transition::Epsilon.new(finish))
          else
            raise "Unexpected work item: #{node.inspect}"
          end
        end

        @match_finish.label.replace(@labels.next)
        @start_state
      end

      private

      def pop_work
        @worklist.pop
      end

      def push_work(work)
        work.reverse_each { |work_item| @worklist << work_item }
      end

      def quantify(quantifier, start, finish)
        work = []

        case quantifier
        when Quantifier::Once
          yield start, finish, work
        when Quantifier::ZeroOrMore
          yield start, start, work
          work << [AddEpsilon, start, finish]
        when Quantifier::OneOrMore
          yield start, finish, work
          work << [AddEpsilon, finish, start]
        when Quantifier::Optional
          yield start, finish, work
          work << [AddEpsilon, start, finish]
        when Quantifier::Exact
          states = [start, *(quantifier.value - 1).times.map { NFA::State.new(@labels.next) }, finish]

          quantifier.value.times do |index|
            yield states[index], states[index + 1], work
          end
        when Quantifier::AtLeast
          states = [start, *(quantifier.value - 1).times.map { NFA::State.new(@labels.next) }, finish]

          quantifier.value.times do |index|
            yield states[index], states[index + 1], work
          end

          work << [AddEpsilon, states[-1], states[-2]]
        when Quantifier::Range
          states = [start, *(quantifier.upper - 1).times.map { NFA::State.new(@labels.next) }, finish]

          quantifier.upper.times do |index|
            yield states[index], states[index + 1], work
          end

          (quantifier.upper - quantifier.lower).times do |index|
            work << [AddEpsilon, states[quantifier.lower + index], states[-1]]
          end
        else
          raise quantify
        end

        push_work(work)
      end

      AddEpsilon = Object.new
      private_constant(:AddEpsilon)
    end
  end
end
