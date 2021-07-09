# frozen_string_literal: true

module RegularExpression
  # The Compiler module translate an NFA to compiled bytecode through abstract
  # interpretation.
  class Compiler
    def compile(nfa)
      builder = Bytecode::Builder.new

      # For each state in the NFA.
      states(nfa).each do |state|
        # Label the start of the state.
        builder.mark_label(:"state#{state.object_id}")

        case state
        when NFA::FinishState
          builder.push(Bytecode::Insns::Finish.new)
        when NFA::State
          # Other states have transitions out of them. Go through each transition.
          state.transitions.each do |transition|
            case transition
            when NFA::Transition::Set
              # For the set transition, we want to try to read the given
              # character, and if we find it, jump to the target state's code.
              raise("Expected transition values to be of size 1") unless transition.values.size == 1
              raise("Cannot yet handle inverted transitions") if transition.invert

              builder.push(Bytecode::Insns::Read.new(transition.values.first, :"state#{transition.state.object_id}"))
            when NFA::Transition::Epsilon
              # Handled below.
            else
              raise("Unknown nfa transition type: #{transition.class}")
            end
          end

          # Do we have an epsilon transition? If so we handle it last, as fallthrough.
          epsilon_transition = state.transitions.find { |t| t.is_a?(NFA::Transition::Epsilon) }

          if epsilon_transition
            # Jump to the state the epsilon transition takes us to.
            builder.push(Bytecode::Insns::Jump.new(:"state#{epsilon_transition.state.object_id}"))
          else
            # With no epsilon transition, no transitions match, which means we jump to the failure case.
            builder.push(Bytecode::Insns::Jump.new(:fail))
          end
        else
          raise("Unknown nfa state type: #{state.class}")
        end
      end

      # We always have a fialure case - it's just the failure instruction.
      builder.mark_label :fail
      builder.push Bytecode::Insns::Fail.new

      builder.build
    end

    # Get all the states in the NFA.
    def states(nfa)
      states = Set.new
      worklist = [nfa]

      # Never recurse a graph in a compiler! We don't know how deep it is and
      # don't want to limit how large a program we can accept due to arbitrary
      # stack space. Always use a worklist.
      until worklist.empty?
        state = worklist.pop
        next if states.include?(state)

        states.add(state)
        worklist.push(*state.transitions.map(&:state))
      end

      states.to_a
    end
  end
end
