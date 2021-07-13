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
      label = -> (state, index = 0) { :"state_#{state.object_id}_#{index}" }

      visited = Set.new
      worklist = [[nfa, Insns::Jump.new(:fail)]]

      # For each state in the NFA.
      until worklist.empty?
        state, fallback = worklist.pop

        next if visited.include?(state)
        visited.add(state)

        # Label the start of the state.
        builder.mark_label(label[state])

        if state.is_a?(NFA::FinishState)
          builder.push(Insns::Match.new)
          next
        end

        # Other states have transitions out of them. Go through each
        # transition.
        state.transitions.each_with_index do |transition, index|
          builder.mark_label(label[state, index])

          case transition
          when NFA::Transition::BeginAnchor
            builder.push(Insns::GuardBegin.new(label[transition.state]))
          when NFA::Transition::EndAnchor
            builder.push(Insns::GuardEnd.new(label[transition.state]))
          when NFA::Transition::Any
            builder.push(Insns::JumpAny.new(label[transition.state]))
          when NFA::Transition::Value
            builder.push(Insns::JumpValue.new(transition.value, label[transition.state]))
          when NFA::Transition::Invert
            builder.push(Insns::JumpValuesInvert.new(transition.values, label[transition.state]))
          when NFA::Transition::Range
            if transition.invert
              builder.push(Insns::JumpRangeInvert.new(transition.left, transition.right, label[transition.state]))
            else
              builder.push(Insns::JumpRange.new(transition.left, transition.right, label[transition.state]))
            end
          when NFA::Transition::Epsilon
            builder.push(Insns::Jump.new(label[transition.state]))
          else
            raise
          end

          next_fallback =
            if state.transitions.length > 1 && index != state.transitions.length - 1
              Insns::Jump.new(label[state, index + 1])
            else
              fallback
            end

          worklist.push([transition.state, next_fallback])
        end

        # If we don't have one of the transitions that always executes, then we
        # need to add the fallback to the output for this state.
        if state.transitions.none? { |t| t.is_a?(NFA::Transition::BeginAnchor) || t.is_a?(NFA::Transition::Epsilon) }
          builder.push(fallback)
        end
      end

      # We always have a failure case - it's just the failure instruction.
      builder.mark_label(:fail)
      builder.push(Insns::Fail.new)
      builder.build
    end

    module Insns
      # If we're at the beginning of the string, then jump to the then
      # instruction. Otherwise fail the entire match.
      GuardBegin = Struct.new(:then)

      # If we're at the end of the string, then jump to the then instruction.
      # Otherwise fail the match at the current index.
      GuardEnd = Struct.new(:then)

      # If it's possible to read a character off the input, then do so and jump
      # to the target instruction.
      JumpAny = Struct.new(:target)

      # If it's possible to read a character off the input and that character
      # matches the char value, then do so and jump to the target instruction.
      JumpValue = Struct.new(:char, :target)
    
      # If it's possible to read a character off the input and that character is
      # not contained within the list of values, then do so and jump to the
      # target instruction.
      JumpValuesInvert = Struct.new(:values, :target)

      # If it's possible to read a character off the input and that character is
      # within the range of possible values, then do so and jump to the target
      # instruction.
      JumpRange = Struct.new(:left, :right, :target)

      # If it's possible to read a character off the input and that character is
      # not within the range of possible values, then do so and jump to the
      # target instruction.
      JumpRangeInvert = Struct.new(:left, :right, :target)

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
