# frozen_string_literal: true

module RegularExpression
  module Compiler
    module Ruby
      class Compiled
        attr_reader :source

        def initialize(source)
          @source = source
        end

        def to_proc
          eval(source) # rubocop:disable Security/Eval
        end
      end

      # Generate Ruby code for a CFG. This looks just like the intepreter, but
      # abstracted in time one level!
      # rubocop:disable Layout/LineLength
      def self.compile(cfg, schedule)
        ruby_src = []
        ruby_src.push "-> (string) {"
        ruby_src.push "  start_n = 0"
        ruby_src.push "  stack = []"
        ruby_src.push "  while start_n <= string.size"
        ruby_src.push "    string_n = start_n"
        ruby_src.push "    block = #{cfg.start.name.inspect}"
        ruby_src.push "    loop do"
        ruby_src.push "      case block"

        schedule.each_with_index do |block, n|
          prev_block = schedule[n - 1]
          next_block = schedule[n + 1]
          falls_through_from_prev = block.preds == [prev_block]

          if falls_through_from_prev
            ruby_src.push "      # #{block.name}:"
          else
            ruby_src.push "      when #{block.name.inspect}"
          end

          block.insns.each do |insn|
            case insn
            when Bytecode::Insns::PushIndex
              ruby_src.push "        stack << string_n"
            when Bytecode::Insns::PopIndex
              ruby_src.push "        string_n = stack.pop"
            when Bytecode::Insns::TestBegin
              ruby_src.push "        flag = start_n == 0"
            when Bytecode::Insns::TestEnd
              ruby_src.push "        flag = string_n == string.size"
            when Bytecode::Insns::TestAny
              ruby_src.push "        flag = string_n < string.size"
              ruby_src.push "        string_n += 1 if flag"
            when Bytecode::Insns::TestValue
              ruby_src.push "        flag = string_n < string.size && string[string_n] == #{insn.char.inspect}"
              ruby_src.push "        string_n += 1 if flag"
            when Bytecode::Insns::TestValuesInvert
              ruby_src.push "        flag = string_n < string.size && !#{insn.chars.inspect}.include?(string[string_n])"
              ruby_src.push "        string_n += 1 if flag"
            when Bytecode::Insns::TestRange
              ruby_src.push "        flag = string_n < string.size && string[string_n] >= #{insn.left.inspect} && string[string_n] <= #{insn.right.inspect}"
              ruby_src.push "        string_n += 1 if flag"
            when Bytecode::Insns::TestRangeInvert
              ruby_src.push "        flag = string_n < string.size && (string[string_n] < #{insn.left.inspect} || string[string_n] > #{insn.right.inspect})"
              ruby_src.push "        string_n += 1 if flag"
            when Bytecode::Insns::Branch
              ruby_src.push "        if flag"
              true_block = cfg.exit_map[insn.true_target]
              ruby_src.push "          block = #{true_block.name.inspect}"
              falls_through_to_true = next_block == true_block && next_block.preds == [block]
              if falls_through_to_true
                ruby_src.push "          # falls through"
              else
                ruby_src.push "          next"
              end
              ruby_src.push "        else"
              false_block = cfg.exit_map[insn.false_target]
              ruby_src.push "          block = #{false_block.name.inspect}"
              falls_through_to_false = next_block == false_block && next_block.preds == [block]
              if falls_through_to_false
                ruby_src.push "          # falls through"
              else
                ruby_src.push "          next"
              end
              ruby_src.push "        end"
            when Bytecode::Insns::Jump
              ruby_src.push "        block = #{cfg.exit_map[insn.target].name.inspect}"
              ruby_src.push "        next"
            when Bytecode::Insns::Match
              ruby_src.push "        return start_n"
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
        ruby_src.push "  nil"
        ruby_src.push "}"
        ruby_src.push ""

        Compiled.new(ruby_src.join($/))
      end
      # rubocop:enable Layout/LineLength
    end
  end
end
