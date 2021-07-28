# frozen_string_literal: true

module RegularExpression
  class Pattern
    class Deoptimize < RuntimeError
    end

    attr_reader :source, :flags, :bytecode

    def initialize(source, flags = nil)
      @source = source
      @flags = Flags.parse(flags)
      @bytecode = Bytecode.compile(NFA.build(Parser.new.parse(source, @flags)))
    end

    def compile(compiler: Compiler::X86)
      cfg = CFG.build(bytecode)
      schedule = Scheduler.schedule(cfg)

      redefine_run(&compiler.compile(cfg, schedule))
    end

    def profile(compiler: Compiler::X86, threshold: 100, speculative: false)
      interpreter = Interpreter.new(bytecode)
      profiling_data = Interpreter.empty_profiling_data
      iteration = threshold

      # Replace with a profiling interpreter version of run
      profiling_impl = lambda do |s1|
        if (iteration -= 1).negative?
          compiled

          cfg = CFG.build(bytecode, profiling_data)
          Phases::Uncommon.apply(cfg) if speculative
          schedule = Scheduler.schedule(cfg)
          compiled = compiler.compile(cfg, schedule).to_proc

          # Replace with a compiled version of run
          redefine_run do |s2|
            compiled.call(s2)
          rescue Deoptimize
            deoptimized
            iteration = threshold
            redefine_run(&profiling_impl)
            profiling_impl.call(s2)
          end
        end

        interpreter.interpret(s1, profiling_data)
      end

      redefine_run(&profiling_impl)
    end

    def match?(string)
      !run(string).nil?
    end

    def match(string)
      indices = run(string)
      MatchData.new(string, indices, bytecode.captures) if indices
    end

    def =~(string)
      indices = run(string)
      indices[0] if indices
    end

    def ==(other)
      source == other.source && flags == other.flags
    end

    def compiled
      # Extension point for testing.
    end

    def deoptimized
      # Extension point for testing.
    end

    private

    # This is the actual method that runs whatever compiled version we're
    # currently using against an input string. The entrypoint methods #match?
    # and #match will call this method and use its result.
    def run(string)
      Interpreter.new(bytecode).match(string)
    end

    def redefine_run(&block)
      # Undefining the method so that we don't get a warning
      singleton_class.undef_method(:run)

      # Redefine the match? method with the given block
      define_singleton_method(:run, &block)
    end
  end
end
