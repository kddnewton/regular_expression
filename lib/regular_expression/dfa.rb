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
      def build(nfa_start_state)
        nfa_start_states = follow_epsilon_transitions_from([nfa_start_state])
        dfa_start_state = NFA::StartState.new(nfa_start_states.map(&:label).join(","))

        # dfa_states is a hash that points from a set of states in the NFA to the
        # new state in the DFA.
        dfa_states = { nfa_start_states => dfa_start_state }

        worklist = [nfa_start_states]

        until worklist.empty?
          current_nfa_states = worklist.pop
          current_dfa_state = dfa_states[current_nfa_states]

          nfa_transitions = []

          # First, we're going to build up a list of transitions that exit out
          # of the current set of states that we're looking at. We'll initialize
          # them to an empty array which is going to eventually represent the
          # set of states that that transition transitions to.
          current_nfa_states.each do |nfa_state|
            nfa_state.transitions.each do |nfa_transition|
              unless nfa_transition.is_a?(NFA::Transition::Epsilon)
                nfa_transitions << nfa_transition
              end
            end
          end

          # Second, we're going to apply each of those transitions to each of
          # the states in our current set to determine where we could end up
          # for any of the transitions.
          nfa_transitions.each do |nfa_transition|
            next_nfa_states = []

            current_nfa_states.each do |current_nfa_state|
              current_nfa_state.transitions.each do |current_nfa_transition|
                next_nfa_states << current_nfa_transition.state if nfa_transition.matches?(current_nfa_transition)
              end
            end

            # Now that we have a full set of states that this transition goes
            # to, we're going to create a transition in our DFA that represents
            # this transition.
            next_nfa_states = follow_epsilon_transitions_from(next_nfa_states)

            unless dfa_states.key?(next_nfa_states)
              # Make sure we check the next states.
              worklist << next_nfa_states
            end

            # If any of the NFA states is a finish state, the DFA state
            # should be too.
            dfa_state_class =
              if next_nfa_states.any? { |state| state.is_a?(NFA::FinishState) }
                NFA::FinishState
              else
                NFA::State
              end

            # Skip duplicate value transitions.
            is_duplicate =
              nfa_transition.is_a?(NFA::Transition::Value) &&
              current_dfa_state.transitions.any? do |t|
                t.is_a?(NFA::Transition::Value) && t.matches?(nfa_transition)
              end

            next_dfa_state =
              dfa_states[next_nfa_states] ||=
                dfa_state_class.new(next_nfa_states.map(&:label).join(","))
            current_dfa_state.push(nfa_transition.copy(next_dfa_state)) unless is_duplicate
          end
        end

        # Return the start state of the new DFA.
        dfa_start_state
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
      def follow_epsilon_transitions_from(nfa_states)
        nfa_states = [*nfa_states]
        index = 0

        while index < nfa_states.length
          nfa_states[index].transitions.each do |nfa_transition|
            if nfa_transition.is_a?(NFA::Transition::Epsilon) && !nfa_states.include?(nfa_transition.state)
              nfa_states << nfa_transition.state
            end
          end

          index += 1
        end

        nfa_states
      end
    end
  end
end
