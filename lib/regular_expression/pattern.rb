# frozen_string_literal: true

module RegularExpression
  class Pattern
    attr_reader :bytecode

    def initialize(source)
      ast = Parser.new.parse(source)
      @bytecode = Bytecode.compile(ast.to_nfa)
    end

    def compile(compiler: Generator::X86)
      cfg = CFG.build(bytecode)

      singleton_class.undef_method(:match?)
      define_singleton_method(:match?, &compiler.compile(cfg))
    end

    def match?(string)
      Interpreter.new(bytecode).match?(string)
    end
  end
end
