# frozen_string_literal: true

module RegularExpression
  module Optimize
    class << self
      def optimize(state)
        state.transitions.each do |transition|
          optimize(transition.state)

          if set?(transition) && transition.state.transitions.any? && transition.state.transitions.all? { |transition| set?(transition) }
            state.transitions.delete(transition)

            transition.state.transitions.each do |next_transition|
              new_transition =
                NFA::Transition::Set.new(
                  next_transition.state,
                  transition.values.product(next_transition.values).map(&:join)
                )

              state.add_transition(new_transition)
            end
          end
        end
      end

      private

      def set?(transition)
        transition.is_a?(NFA::Transition::Set)
      end
    end
  end
end
