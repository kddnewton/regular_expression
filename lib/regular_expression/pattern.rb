# frozen_string_literal: true

module RegularExpression
  class Pattern
    attr_reader :bytecode

    def initialize(source)
      parser = RegularExpression::Parser.new
      nfa = parser.parse(source).to_nfa

      @bytecode = RegularExpression::Bytecode.compile(nfa)
    end

    def compile(compiler: RegularExpression::Generator::X86)
      cfg = RegularExpression::CFG.build(bytecode)

      singleton_class.undef_method(:match?)
      define_singleton_method(:match?, &compiler.compile(cfg))
    end

    def match?(string)
      RegularExpression::Interpreter.new(bytecode).match?(string)
    end
  end
end
