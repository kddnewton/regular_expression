# frozen_string_literal: true

module RegularExpression
  module DFA
    class << self
      # This method converts a non-deterministic finite automata into a
      # deterministic finite automata. The best link I could find that describes
      # the general approach taken here is here:
      #
      #   https://www.geeksforgeeks.org/conversion-from-nfa-to-dfa/
      #
      # The general idea is to walk the state machine and make it such that
      # for any given state and input you deterministically know which state the
      # machine should transition to. In effect, this means we're removing all
      # epsilon transitions.
      def build(nfa)
        start_key = next_states_for([nfa])
        worklist = [start_key]

        # Result is a hash that points from a set of states in the NFA to the
        # new state in the DFA.
        result = {}

        until worklist.empty?
          states = worklist.pop

          next if result.key?(states)
          result[states] = NFA::State.new(states.map(&:label).join(","))

          transitions = {}

          # First, we're going to build up a list of transitions that exit out
          # of the current set of states that we're looking at. We'll initialize
          # them to an empty array which is going to eventually represent the
          # set of states that that transition transitions to.
          states.each do |state|
            state.transitions.each do |transition|
              unless transition.is_a?(NFA::Transition::Epsilon)
                transitions[transition] = []
              end
            end
          end

          # Second, we're going to apply each of those transitions to each of
          # the states in our current set to determine where we could end up
          # for any of the transitions.
          transitions.each do |transition, next_states|
            states.each do |current_state|
              current_state.transitions.each do |current_transition|
                next_states << current_transition.state if transition.matches?(current_transition)
              end
            end

            # Now that we have a full set of states that this transition goes
            # to, we're going to create a transition in our DFA that represents
            # this transition.
            next_key = next_states_for(next_states)

            unless result.key?(next_key)
              # Make sure we check the next states.
              worklist << next_key
            end

            new_state = (result[next_key] ||= NFA::State.new(next_key.map(&:label).join(",")))
            result[states].add_transition(transition.copy(new_state))
          end
        end

        # Return the start state of the new DFA.
        result[start_key]
      end

      private

      # Get the set of states that correspond to the given set of states but
      # walked through any epsilon transitions. So for example if we have the
      # following NFA which represents the a?a?b language:
      #
      # ─> (1) ─a─> (2) ─a─> (3) ─b─> [4]
      #     └───ε-──^└───ε-───^
      #
      # Then if you passed [1] into here we would return [1,2,3].
      def next_states_for(states)
        next_states = [*states]
        index = 0

        while index < next_states.length
          next_states[index].transitions.each do |transition|
            if transition.is_a?(NFA::Transition::Epsilon) && !next_states.include?(transition.state)
              next_states << transition.state
            end
          end

          index += 1
        end

        next_states
      end
    end
  end
end
