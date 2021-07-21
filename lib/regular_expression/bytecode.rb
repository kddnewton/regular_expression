# frozen_string_literal: true

module RegularExpression
  # The bytecode module defines instructions, and has a compiled object for
  # storing a stream of them, and a builder object for creating the compiled
  # object.
  module Bytecode
    # Never recurse a graph in a compiler! We don't know how deep it is and
    # don't want to limit how large a program we can accept due to arbitrary
    # stack space. Always use a worklist.
    def self.compile(nfa)
      builder = Builder.new
      label = ->(state, index = 0) { :"state_#{state.object_id}_#{index}" }

      visited = Set.new
      worklist = [[nfa, [:jump_to_fail]]]

      # For each state in the NFA.
      until worklist.empty?
        state, fallback = worklist.pop
        next if visited.include?(state)

        # Label the start of the state.
        builder.mark_label(label[state])
        visited.add(state)

        if state.is_a?(NFA::FinishState)
          builder.push(Insns::Match.new)
          next
        end

        needs_final_transition = false
        needs_epsilon = false

        # Other states have transitions out of them. Go through each
        # transition.
        state.transitions.each_with_index do |transition, index|
          builder.mark_label(label[state, index])

          if state.transitions.length > 1 && index != state.transitions.length - 1
            builder.push(Insns::PushIndex.new)
          end

          if !transition.is_a?(NFA::Transition::Epsilon)
            case transition
            when NFA::Transition::BeginAnchor
              builder.push(Insns::TestBegin.new)
            when NFA::Transition::EndAnchor
              builder.push(Insns::TestEnd.new)
            when NFA::Transition::StartCapture
              builder.push(
                Insns::StartCapture.new(transition.name),
                Insns::Jump.new(label[transition.state])
              )
            when NFA::Transition::EndCapture
              builder.push(
                Insns::EndCapture.new(transition.name),
                Insns::Jump.new(label[transition.state])
              )
            when NFA::Transition::Any
              builder.push(Insns::TestAny.new)
            when NFA::Transition::Value
              builder.push(Insns::TestValue.new(transition.value))
            when NFA::Transition::Invert
              builder.push(Insns::TestValuesInvert.new(transition.values))
            when NFA::Transition::Range
              if transition.invert
                builder.push(Insns::TestRangeInvert.new(transition.left, transition.right))
              else
                builder.push(Insns::TestRange.new(transition.left, transition.right))
              end
            when NFA::Transition::Type
              builder.push(Insns::TestType.new(CharacterType.new(transition.type)))
            when NFA::Transition::PositiveLookahead
              builder.push(Insns::TestPositiveLookahead.new(transition.value))
            when NFA::Transition::NegativeLookahead
              builder.push(Insns::TestNegativeLookahead.new(transition.value))
            else
              raise
            end

            true_target = label[transition.state]

            # Some practical shortcuts to avoid jumping to instructions that
            # just jump to another instruction.
            final_transition = index + 1 == state.transitions.length
            if final_transition && fallback == [:jump_to_fail]
              # If this is the final transition, and the fallback is to jump
              # to fail, just jump to fail.
              false_target = :fail
            elsif state.transitions[index + 1].is_a?(NFA::Transition::Epsilon)
              # If the next transition is epsilon, just jump to where it jumps
              # to.
              false_target = label[state.transitions[index + 1].state]
              needs_epsilon = false
            else
              # It's none of these and we really do need the final transition
              # and to jump to whatever it does.
              needs_final_transition = true if final_transition
              false_target = label[state, index + 1]
            end

            builder.push(Insns::Branch.new(true_target, false_target))
          elsif needs_epsilon
            builder.push(Insns::Jump.new(label[transition.state]))
          else
            needs_epsilon = true
          end

          next_fallback =
            if state.transitions.length > 1 && index != state.transitions.length - 1
              [Insns::PopIndex.new, Insns::Jump.new(label[state, index + 1])]
            else
              fallback
            end

          worklist.push([transition.state, next_fallback])
        end

        builder.mark_label(label[state, state.transitions.size]) if needs_final_transition

        # If we don't have one of the transitions that always executes, then we
        # need to add the fallback to the output for this state.
        if state.transitions.none? { |t| t.is_a?(NFA::Transition::BeginAnchor) || t.is_a?(NFA::Transition::Epsilon) }
          fallback = [Insns::Jump.new(:fail)] if fallback == [:jump_to_fail]
          builder.push(*fallback)
        end
      end

      # We always have a failure case - it's just the failure instruction.
      builder.mark_label(:fail)
      builder.push(Insns::Fail.new)
      builder.build
    end

    module Insns
      # Push the current string index onto the stack. This is necessary to
      # support backtracking so that we can pop it off later when we want to go
      # backward.
      PushIndex = Class.new

      # Pop the string index off the stack. This is necessary so that we can
      # support backtracking.
      PopIndex = Class.new

      # If we're at the beginning of the string, then set the flag, otherwise
      # clear it.
      TestBegin = Class.new

      # If we're at the end of the string, then jump to the then instruction,
      # otherwise clear it.
      TestEnd = Class.new

      StartCapture = Struct.new(:name)
      EndCapture = Struct.new(:name)

      # If it's possible to read a character off the input, then do so and set
      # the flag, otherwise clear it.
      TestAny = Class.new

      # If it's possible to read a character off the input and that character
      # matches the char value, then do so and set the flag, otherwise clear it.
      TestValue = Struct.new(:char)

      # If it's possible to read a character off the input and that character is
      # included in the POSIX character type class defined by the type variable,
      # then do so a set the flag, otherwise clear it.
      TestType = Struct.new(:type)

      # If it's possible to read a character off the input and that character is
      # not contained within the list of values, then do so and set the flag,
      # otherwise clear it
      TestValuesInvert = Struct.new(:chars)

      # If it's possible to read a character off the input and that character is
      # within the range of possible values, then do so set the flag, otherwise
      # clear it
      TestRange = Struct.new(:left, :right)

      # If it's possible to read a character off the input and that character is
      # not within the range of possible values, then do so and set the flag,
      # otherwise clear it
      TestRangeInvert = Struct.new(:left, :right)

      # If the next characters in the input string match the value of this
      # transition, then set the flag, otherwise clear it
      TestPositiveLookahead = Struct.new(:value)
      TestNegativeLookahead = Struct.new(:value)

      # If the flag has been set, jump to the true target, otherwise if it's
      # been cleared jump to the false target.
      Branch = Struct.new(:true_target, :false_target)

      # Jump directly to the target instruction.
      Jump = Struct.new(:target)

      # Successfully match the string and stop executing instructions.
      Match = Class.new

      # Fail to match the string at the current index. Increment the starting
      # index and try again if possible.
      Fail = Class.new
    end

    class Builder
      attr_reader :insns # Array[Insns]
      attr_reader :labels # Hash[Symbol, Integer]

      def initialize
        @insns = []
        @labels = {}
      end

      def mark_label(label)
        labels[label] = insns.size
      end

      def push(*new_insns)
        insns.push(*new_insns)
      end

      def build
        Compiled.new(insns, labels)
      end
    end

    class Compiled
      attr_reader :insns, :labels

      def initialize(insns, labels)
        @insns = insns
        @labels = labels
      end

      def dump
        output = StringIO.new

        # Labels store name -> address, but if we want to print the label name
        # at its address, we need to store the address to the name as well.
        reverse_labels = {}
        labels.each do |label, n|
          reverse_labels[n] = label
        end

        insns.each_with_index do |insn, n|
          label = reverse_labels[n]
          output.puts("#{label}:") if label
          output.puts("  #{insn}")
        end

        output.string
      end
    end
  end
end
