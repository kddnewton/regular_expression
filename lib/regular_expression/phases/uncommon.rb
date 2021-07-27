# frozen_string_literal: true

module RegularExpression
  module Phases
    # Replaces code that never runs ('uncommon') with deoptimisations.
    module Uncommon
      def self.apply(cfg)
        changes = false

        # An exit is uncommon if its probability is zero.
        uncommon_exits = []
        cfg.blocks.each do |block|
          block.exits.each do |exit|
            probability = exit.metadata[:probability]
            if probability&.zero?
              uncommon_exits.push [block, exit]
            end
          end
        end

        # Redirect uncommon exits to a new deoptimize block.
        uncommon_exits.each do |pred, exit|
          name = :"deoptimize_#{exit.object_id}"
          insns = [Bytecode::Insns::Deoptimize.new]
          preds = [pred]
          exits = []
          deopt = CFG::ExtendedBasicBlock.new(name, insns, preds, exits)
          cfg.replace_exit(pred, exit, deopt)
          changes = true
        end

        # If we changed the graph then we should incrementally run the
        # dead code phase to clean up the graph.
        if changes
          loop do
            break unless Dead.apply(cfg)
          end
        end

        changes
      end
    end
  end
end
