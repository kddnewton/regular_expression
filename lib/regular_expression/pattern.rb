# frozen_string_literal: true

module RegularExpression
  class Pattern
    attr_reader :bytecode

    def initialize(source)
      ast = Parser.new.parse(source)
      @bytecode = Bytecode.compile(ast.to_nfa)
    end

    def compile(compiler: Compiler::X86)
      cfg = CFG.build(bytecode)
      schedule = Scheduler.schedule(cfg)

      redefine_match(&compiler.compile(cfg, schedule))
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
