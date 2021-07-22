# frozen_string_literal: true

module RegularExpression
  class Pattern
    # An object to contain the value of the flags that were set when the pattern
    # was initialized. These match up to the Regexp constants.
    class Flags < Struct.new(:value)
      def extended?
        (value & Regexp::EXTENDED).positive?
      end
    end

    attr_reader :bytecode

    def initialize(source, flags = 0)
      ast = Parser.new.parse(source, Flags.new(flags))
      @bytecode = Bytecode.compile(ast.to_nfa)
    end

    def compile(compiler: Compiler::X86)
      cfg = CFG.build(bytecode)
      schedule = Scheduler.schedule(cfg)

      redefine_match(&compiler.compile(cfg, schedule))
    end

    def profile(compiler: Compiler::X86, threshold: 100)
      interpreter = Interpreter.new(bytecode)
      profiling_data = Interpreter.empty_profiling_data
      iteration = threshold

      # Replace with a profiling interpreter version of match?
      redefine_match do |string|
        if (iteration -= 1).negative?
          cfg = CFG.build(bytecode, profiling_data)
          schedule = Scheduler.schedule(cfg)

          # Replace with a compiled version of match?
          redefine_match(&compiler.compile(cfg, schedule))
        end

        interpreter.interpret(string, profiling_data)
      end
    end

    def match?(string)
      Interpreter.new(bytecode).match?(string)
    end

    private

    def redefine_match(&block)
      singleton_class.undef_method(:match?)
      define_singleton_method(:match?, &block)
    end
  end
end
