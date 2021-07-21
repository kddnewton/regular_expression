# frozen_string_literal: true

module RegularExpression
  class Pattern

    class Deoptimized < Exception
    end

    attr_reader :bytecode

    def initialize(source, flags = nil)
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
      profiling_impl = ->(string) do
        if (iteration -= 1).negative?
          cfg = CFG.build(bytecode, profiling_data)
          schedule = Scheduler.schedule(cfg)
          compiled = compiler.compile(cfg, schedule).to_proc

          # Replace with a compiled version of match?
          redefine_match do |string|
            compiled.call(string)
          rescue Deoptimized
            iteration = threshold
            redefine_match(&profiling_impl)
            profiling_impl.call(string)
          end
        end

        interpreter.interpret(string, profiling_data)
      end

      redefine_match(&profiling_impl)
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
