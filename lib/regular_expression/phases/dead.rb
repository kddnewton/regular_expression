# frozen_string_literal: true

module RegularExpression
  module Phases
    # Removes dead code. Only removes code that is immediately dead - this may
    # reveal more dead code, so you should run this phase incrementally until
    # you reach a fix point.
    module Dead
      def self.apply(cfg)
        # Look for blocks that have no predecessors - excluding the start block.
        dead_blocks = []
        cfg.blocks.each do |block|
          next if block == cfg.start

          if block.preds.empty?
            dead_blocks.push block
          end
        end

        # Remove dead blocks.
        dead_blocks.each do |block|
          cfg.remove block
        end

        # Did we remove any dead code?
        dead_blocks.any?
      end
    end
  end
end
