# frozen_string_literal: true

module RegularExpression
  # The scheduler tells us what order to generate our basic-blocks in.
  # Ideally it minimises jumps and optimises spatial locality.
  module Scheduler
    def self.schedule(cfg)
      schedule = []

      # Naive schedule - just schedule blocks in the order we find them.
      cfg.blocks.each do |block|
        schedule.push block
      end

      schedule
    end

    def self.dump(cfg, schedule)
      io = StringIO.new
      schedule.each do |block|
        io.puts("#{block.name}:")
        block.exits.each { |exit| io.puts("    -> #{cfg.exit_map[exit.label].name} #{exit.metadata.inspect}") }
      end
      io.string
    end
  end
end
