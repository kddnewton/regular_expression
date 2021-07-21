# frozen_string_literal: true

module RegularExpression
  # The CFG is a directed graph of extended basic blocks of bytecode
  # instructions. This module has objects to represent the EBB, a graph object
  # which contains a set of EBB, and a builder that creates a CFG from a
  # compiled bytecode object.
  module CFG
    # A block exit is an edge out of a block. It includes the target label
    # and a metadata hash. Recognised metadata is whether the edge is for
    # a true or false condition, and what the probability of it being taken is.
    BlockExit = Struct.new(:label, :metadata)

    def self.build(compiled)
      # Each label in the compiled bytecode starts a block, as does the first
      # instruction
      all_blocks = { start: 0 }.merge(compiled.labels)
      all_block_addresses = all_blocks.values

      # We're going to create a potentially larger map of labels, and we'll be
      # maintaining a reverse map as well.
      all_labels = compiled.labels.dup
      all_labels_reverse = all_labels.invert

      # These are the blocks we're finding - indexed by their start address.
      blocks = {}

      # Go through each block.
      all_blocks.each do |name, start_n|
        # We're going to collect up the instructions in the block, and the
        # labels it exits to.
        block_insns = []
        block_exits = Set.new

        insn_n = start_n

        loop do
          # Does another instruction jump here? If so it's the end of the EBB,
          # as EBBs have only one entry point.
          if insn_n != start_n && all_block_addresses.include?(insn_n)
            # As the EBB ends here - we should jump to the next EBB.
            target = all_labels_reverse[insn_n]
            unless target
              target = :"extra#{insn_n}"
              all_labels[target] = insn_n
              all_labels_reverse[insn_n] = target
            end
            block_insns.push(Bytecode::Insns::Jump.new(target))
            block_exits.add(BlockExit.new(target, {}))
            break
          end

          # Examine each instruction.
          insn = compiled.insns[insn_n]
          block_insns.push(insn)

          # Remember which blocks exit to this target.
          case insn
          when Bytecode::Insns::PushIndex, Bytecode::Insns::PopIndex,
                Bytecode::Insns::TestBegin, Bytecode::Insns::TestEnd,
                Bytecode::Insns::TestAny, Bytecode::Insns::TestValuesInvert,
                Bytecode::Insns::TestRange, Bytecode::Insns::TestRangeInvert,
                Bytecode::Insns::TestValue, Bytecode::Insns::TestType
            insn_n += 1
          when Bytecode::Insns::Branch
            true_probability = 0.9 # A default 'likely' probability for true.
            block_exits.add(BlockExit.new(insn.true_target, { kind: true, probability: true_probability }))
            block_exits.add(BlockExit.new(insn.false_target, { kind: false, probability: 1.0 - true_probability }))
            break
          when Bytecode::Insns::Jump
            block_exits.add(BlockExit.new(insn.target, {}))
            break
          when Bytecode::Insns::Match, Bytecode::Insns::Fail
            break
          else
            raise
          end
        end

        blocks[start_n] = ExtendedBasicBlock.new(name, block_insns, [], block_exits.to_a)
      end

      # Create a map of jump target labels to the blocks that contain them.
      exit_map = {}
      blocks.each_value do |block|
        block.exits.each do |exit|
          exit_map[exit.label] ||= blocks[all_labels[exit.label]]
        end
      end

      # Now we have forward edges, fill in the predecessors.
      blocks.each_value do |block|
        block.exits.each do |block_exit|
          blocks[all_blocks[block_exit.label]].preds.push block
        end
      end

      start = blocks.values.first
      Graph.new(start, exit_map.merge({ start.name => start }))
    end

    def self.to_dot(cfg)
      graph = Graphviz::Graph.new
      cfg.to_dot(graph)

      Graphviz.output(graph, path: "build/cfg.svg", format: "svg")
      graph.to_dot
    end

    # An Extended Basic Block is a linear sequence of instructions with zero or
    # more predecessors and zero or more exit points.
    class ExtendedBasicBlock
      attr_reader :name, :insns, :preds, :exits

      def initialize(name, insns, preds, exits)
        @name = name
        @insns = insns
        @preds = preds
        @exits = exits
      end

      def dump(blocks, io: $stdout)
        io.puts("#{name}:")
        preds.each { |pred| io.puts("    <- #{pred}") }
        insns.each { |insn| io.puts("  #{insn}") }
        exits.each { |exit| io.puts("    #{exit.label} -> #{blocks[exit.label].name} #{exit.metadata.inspect}") }
      end
    end

    # A graph is a set of EBBs.
    class Graph
      attr_reader :start, :blocks

      def initialize(start, blocks)
        @start = start
        @blocks = blocks
      end

      def dump
        output = StringIO.new
        blocks.each_value { |block| block.dump(blocks, io: output) }
        output.string
      end

      def to_dot(graph)
        nodes = {}

        blocks.each_value do |block|
          label = []

          label.push("#{block.name}:")
          block.insns.each { |insn| label.push("  #{insn}") }

          nodes[block] = graph.add_node(block.object_id, label: label.join($/), labeljust: "l", shape: "box")
        end

        blocks.each_value do |block|
          block.exits.each do |block_exit|
            successor = nodes[blocks[block_exit.label]]
            attributes = {}
            if (kind = block_exit.metadata[:kind])
              attributes["color"] = { true => "green", false => "red" }[kind]
            end
            if (probability = block_exit.metadata[:probability])
              attributes["penwidth"] = 1 + probability * 4
            end
            nodes[block].connect(successor, **attributes)
          end
        end
      end
    end
  end
end
