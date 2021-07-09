# frozen_string_literal: true

module RegularExpression
  module Optimize
    class << self
      def optimize(state, visited = [])
        return if visited.include?(state)
        visited << state

        # First, recurse down such that each state gets touched by the
        # optimization method.
        state.transitions.each do |transition|
          optimize(transition.state, visited)
        end

        # Go through each of the transitions on this state, and if there are
        # multiple set transitions that map to the same destination state, then
        # combine them into one set transition.
        state
          .transitions
          .select { |transition| set?(transition) }
          .group_by(&:state)
          .each do |next_state, transitions|
            if transitions.length > 1
              transitions.each do |transition|
                state.transitions.delete(transition)
              end

              new_transition =
                NFA::Transition::Set.new(
                  next_state,
                  transitions.flat_map(&:values).uniq
                )

              state.add_transition(new_transition)
            end
          end

        # Go through each set transition that points to another set transition
        # and combine them into a single set transition.
        state.transitions.each do |transition|
          if set?(transition) &&
             transition.state.transitions.any? &&
             transition.state.transitions.all? { |transition| set?(transition) }

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

      def set?(transition)
        transition.is_a?(NFA::Transition::Set)
      end
    end
  end
end
