# frozen_string_literal: true

module RegularExpression
  # The Bytecode module defines instructions, and has a Compiled object for storing a stream of them, and a Builder
  # object for creating the Compiled object.
  module Bytecode

    module Insns
      Start = Class.new
      Read = Struct.new(:char, :then)
      Jump = Struct.new(:target)
      Finish = Class.new
      Fail = Class.new
    end

    class Builder

      def initialize
        @insns = []
        @labels = {}
      end

      def mark_label(label)
        @labels[label] = @insns.size
      end

      def push(insn)
        @insns.push insn
      end

      def build
        Compiled.new(@insns, @labels)
      end

    end

    class Compiled

      attr_reader :insns, :labels

      def initialize(insns, labels)
        @insns = insns
        @labels = labels
      end

      def dump
        # Labels store name -> address, but if we want to print the label name at its address, we need to store the
        # address to the name as well.
        reverse_labels = {}
        @labels.each do |label, n|
          reverse_labels[n] = label
        end

        @insns.each_with_index do |insn, n|
          label = reverse_labels[n]
          puts "#{label.to_s}:" if label
          puts "  #{insn}"
        end
      end

    end

  end
end