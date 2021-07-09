# frozen_string_literal: true

module RegularExpression
  module Generator
    module Ruby
      # Generate Ruby code for a CFG. This looks just like the intepreter, but
      # abstracted in time one level!
      def self.generate(cfg)
        ruby_src = []
        ruby_src.push "-> (string) {"
        ruby_src.push "  start_n = 0"
        ruby_src.push "  while start_n < string.size"
        ruby_src.push "    string_n = start_n"
        ruby_src.push "    block = #{cfg.start.name.inspect}"
        ruby_src.push "    while true"
        ruby_src.push "      case block"

        cfg.blocks.each do |block|
          ruby_src.push "      when #{block.name.inspect}"

          block.insns.each do |insn|
            case insn
            when Bytecode::Insns::Any
              ruby_src.push "        if string_n < string.size"
              ruby_src.push "          string_n += 1"
              ruby_src.push "          block = #{cfg.exit_map[insn.then].name.inspect}"
              ruby_src.push "          next"
              ruby_src.push "        end"
            when Bytecode::Insns::Read
              ruby_src.push "        if string[string_n] == #{insn.char.inspect}"
              ruby_src.push "          string_n += 1"
              ruby_src.push "          block = #{cfg.exit_map[insn.then].name.inspect}"
              ruby_src.push "          next"
              ruby_src.push "        end"
            when Bytecode::Insns::Jump
              ruby_src.push "        block = #{cfg.exit_map[insn.target].name.inspect}"
              ruby_src.push "        next"
            when Bytecode::Insns::Match
              ruby_src.push "        return true"
            when Bytecode::Insns::Fail
              ruby_src.push "        start_n += 1"
              ruby_src.push "        break"
            else
              raise
            end
          end
        end

        ruby_src.push "      end"
        ruby_src.push "    end"
        ruby_src.push "  end"
        ruby_src.push "  false"
        ruby_src.push "}"
        ruby_src.join($/)
      end
    end
  end
end
