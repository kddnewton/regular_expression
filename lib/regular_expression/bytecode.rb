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
      label = ->(state) { :"state_#{state.object_id}" }

      visited = Set.new
      worklist = [nfa]

      # For each state in the NFA.
      until worklist.empty?
        state = worklist.pop

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
        state.transitions.each do |transition|
          case transition
          when NFA::Transition::BeginAnchor
            builder.push(Insns::GuardBegin.new(label[transition.state]))
          when NFA::Transition::EndAnchor
            builder.push(Insns::GuardEnd.new(label[transition.state]))
          when NFA::Transition::Any
            builder.push(Insns::Any.new(label[transition.state]))
          when NFA::Transition::Set
            raise if transition.invert
            builder.push(Insns::Set.new(transition.values, label[transition.state]))
          when NFA::Transition::Value
            builder.push(Insns::Value.new(transition.value, label[transition.state]))
          when NFA::Transition::Range
            raise if transition.invert
            builder.push(Insns::Range.new(transition.left, transition.right, label[transition.state]))
          when NFA::Transition::Epsilon
            builder.push(Insns::Jump.new(label[transition.state]))
          else
            raise
          end

          worklist.push(transition.state)
        end

        if state.transitions.none? { |t| t.is_a?(NFA::Transition::BeginAnchor) }
          builder.push(Insns::Jump.new(:fail))
        end
      end

      # We always have a failure case - it's just the failure instruction.
      builder.mark_label(:fail)
      builder.push(Insns::Fail.new)
      builder.build
    end

    module Insns
      # Fail unless at the beginning of the string, transition to then
      GuardBegin = Struct.new(:then)

      # Fail unless at the end of the string, transition to then
      GuardEnd = Struct.new(:then)

      # Read off 1 character if possible, transition to then
      Any = Struct.new(:then)

      # Read off 1 character and match against char, transition to then
      Value = Struct.new(:char, :then)
    
      # Read off 1 character and test that it's in the value list, transition to then
      Set = Struct.new(:values, :then)

      # Read off 1 character and test that it's between left and right, transition to then
      Range = Struct.new(:left, :right, :then)

      # Jump to another instruction
      Jump = Struct.new(:target)

      # Successfully match against the given string
      Match = Class.new

      # Fail to match against the given string
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
        # Labels store name -> address, but if we want to print the label name
        # at its address, we need to store the address to the name as well.
        reverse_labels = {}
        labels.each do |label, n|
          reverse_labels[n] = label
        end

        insns.each_with_index do |insn, n|
          label = reverse_labels[n]
          puts "#{label.to_s}:" if label
          puts "  #{insn}"
        end
      end
    end
  end
end
