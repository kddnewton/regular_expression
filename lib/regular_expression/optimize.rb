# frozen_string_literal: true

module RegularExpression
  module NFA::Transition
    class BeginAnchor
      def combinable?
        false
      end
    end

    class EndAnchor
      def combinable?
        false
      end
    end

    class Any
      def combinable?
        false
      end
    end

    class Set
      def combinable?
        true
      end
    end

    class Epsilon
      def combinable?
        true
      end

      def values
        [""]
      end
    end
  end

  module Optimize
    def self.optimize(state, visited = [])
      state.transitions.each do |transition|
        optimize(transition.state, visited)

        if transition.is_a?(NFA::Transition::Set)
          if transition.state.transitions.any? && transition.state.transitions.all?(&:combinable?)
            state.transitions.delete(transition)

            transition.state.transitions.each do |next_transition|
              values = transition.values.product(next_transition.values).map(&:join)
              state.add_transition(NFA::Transition::Set.new(next_transition.state, values))
            end
          end
        end
      end
    end
  end
end
