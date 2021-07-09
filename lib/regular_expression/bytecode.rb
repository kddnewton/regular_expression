# frozen_string_literal: true

module RegularExpression
  # The Bytecode module defines instructions, and has a Compiled object for
  # storing a stream of them, and a Builder object for creating the Compiled
  # object.
  module Bytecode
    class << self
      def compile(nfa)
        builder = Builder.new

        each_state(nfa) do |state|
          # Label the start of the state.
          builder.mark_label(:"state#{state.object_id}")

          case state
          when NFA::FinishState
            builder.push(Insns::Finish.new)
          when NFA::State
            # Other states have transitions out of them. Go through each
            # transition.
            state.transitions.each do |transition|
              case transition
              when NFA::Transition::Set
                # For the set transition, we want to try to read the given
                # character, and if we find it, jump to the target state's code.
                raise("Expected transition values to be of size 1") unless transition.values.size == 1
                raise("Cannot yet handle inverted transitions") if transition.invert

                builder.push(Insns::Read.new(transition.values.first, :"state#{transition.state.object_id}"))
              when NFA::Transition::Epsilon
                # Handled below.
              else
                raise("Unknown nfa transition type: #{transition.class}")
              end
            end

            # Do we have an epsilon transition? If so we handle it last, as
            # fallthrough.
            epsilon_transition = state.transitions.find { |t| t.is_a?(NFA::Transition::Epsilon) }

            if epsilon_transition
              # Jump to the state the epsilon transition takes us to.
              builder.push(Insns::Jump.new(:"state#{epsilon_transition.state.object_id}"))
            else
              # With no epsilon transition, no transitions match, which means we
              # jump to the failure case.
              builder.push(Insns::Jump.new(:fail))
            end
          else
            raise("Unknown nfa state type: #{state.class}")
          end
        end

        # We always have a failure case - it's just the failure instruction.
        builder.mark_label(:fail)
        builder.push(Insns::Fail.new)
        builder.build
      end

      private

      def each_state(nfa)
        visited = Set.new

        # Never recurse a graph in a compiler! We don't know how deep it is and
        # don't want to limit how large a program we can accept due to arbitrary
        # stack space. Always use a worklist.
        worklist = [nfa]

        # For each state in the NFA.
        until worklist.empty?
          state = worklist.pop

          next if visited.include?(state)
          visited.add(state)

          yield state
          worklist.push(*state.transitions.map(&:state))
        end
      end
    end

    module Insns
      Start = Class.new
      Read = Struct.new(:char, :then)
      Jump = Struct.new(:target)
      Finish = Class.new
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

      def push(insn)
        insns.push(insn)
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
