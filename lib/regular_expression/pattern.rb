# frozen_string_literal: true

module RegularExpression
  class Pattern
    attr_reader :bytecode

    def initialize(source)
      parser = RegularExpression::Parser.new
      nfa = parser.parse(source).to_nfa

      @bytecode = RegularExpression::Bytecode.compile(nfa)
    end

    def compile(compiler: RegularExpression::Generator::Native)
      builder = RegularExpression::CFG::Builder.new

      singleton_class.undef_method(:match?)
      define_singleton_method(:match?, &compiler.compile(builder.build(bytecode)))
    end

    def match?(string)
      interpreter = RegularExpression::Interpreter.new
      interpreter.match?(bytecode, string)
    end
  end
end
