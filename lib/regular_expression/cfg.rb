# frozen_string_literal: true

module RegularExpression
  # The CFG is a directed graph of extended basic blocks of bytecode
  # instructions. This module has objects to represent the EBB, a graph object
  # which contains a set of EBB, and a builder that creates a CFG from a
  # compiled bytecode object.
  module CFG
    # An Extended Basic Block is a linear sequence of instructions with one
    # entry point and zero or more exit points.
    class ExtendedBasicBlock
      attr_reader :name, :insns, :exits

      def initialize(name, insns, exits)
        @name = name
        @insns = insns
        @exits = exits
      end

      def dump(exit_map)
        puts "#{name}:"
        @insns.each do |insn|
          puts "  #{insn}"
        end
        @exits.each do |exit|
          puts "    #{exit} -> #{exit_map[exit].name}"
        end
      end
    end

    # A graph is a set of EBBs.
    class Graph
      attr_reader :blocks, :exit_map

      def initialize(blocks, exit_map)
        @blocks = blocks
        @exit_map = exit_map
      end

      def start
        @blocks.first
      end

      def dump
        @blocks.each do |block|
          block.dump @exit_map
        end
      end

      def to_dot(graph)
        nodes = {}

        @blocks.each do |block|
          label = []
          label.push "#{block.name}:"
          block.insns.each do |insn|
            label.push "  #{insn.to_s}"
          end
          nodes[block] = graph.add_node(block.object_id, label: label.join($/), labeljust: "l", shape: "box")
        end

        @blocks.each do |block|
          successors = block.exits.map { |exit| nodes[@exit_map[exit]] }.uniq
          successors.each do |successor|
            nodes[block].connect successor
          end
        end
      end

      def self.to_dot(cfg)
        require "graphviz"
        graph = Graphviz::Graph.new
        cfg.to_dot(graph)

        Graphviz.output(graph, path: "build/cfg.svg", format: "svg")
        graph.to_dot
      end
    end

    class Builder
      def build(compiled)
        # Each label in the compiled bytecode starts a block, as does the first instruction
        all_blocks = {start: 0}.merge(compiled.labels)
        all_block_addresses = all_blocks.values

        # We're going to create a potentially larger map of labels, and we'll be maintaining a reverse map as well.
        all_labels = compiled.labels.dup
        all_labels_reverse = Hash[all_labels.to_a.map(&:reverse)]

        # These are the blocks we're finding - indexed by their start address.
        blocks = {}

        # Go through each block.
        all_blocks.each do |name, start_n|
          # We're goign to collect up the instructions in the block, and the labels it exits to.
          block_insns = []
          block_exits = Set.new

          insn_n = start_n
          loop do
            # Does another instruction jump here? If so it's the end of the EBB, as EBBs have only one entry point.
            if insn_n != start_n && all_block_addresses.include?(insn_n)
              # As the EBB ends here - we should jump to the next EBB.
              target = all_labels_reverse[insn_n]
              unless target
                target = :"extra#{insn_n}"
                all_labels[target] = insn_n
                all_labels_reverse[insn_n] = target
              end
              block_insns.push Bytecode::Insns::Jump.new(target)
              block_exits.add target
              break
            end

            # Examine each instruction.
            insn = compiled.insns[insn_n]
            block_insns.push insn

            case insn
            when Bytecode::Insns::BeginAnchor, Bytecode::Insns::EndAnchor,
                 Bytecode::Insns::Any, Bytecode::Insns::Set, Bytecode::Insns::Range,
                 Bytecode::Insns::Value
              # Remember this block exits to this target.
              block_exits.add insn.then
              insn_n += 1
              next
            when Bytecode::Insns::Jump
              # Remember this block exits to this target.
              block_exits.add insn.target
              break
            when Bytecode::Insns::Match, Bytecode::Insns::Fail
              # Ends the block.
              break
            else
              raise
            end
          end

          blocks[start_n] = ExtendedBasicBlock.new(name, block_insns, block_exits.to_a)
        end

        # Create a map of jump target labels to the blocks that contain them.
        exit_map = {}
        blocks.each_value do |block|
          block.exits.each do |exit|
            exit_map[exit] ||= blocks[all_labels[exit]]
          end
        end

        Graph.new(blocks.values, exit_map)
      end
    end
  end
end
