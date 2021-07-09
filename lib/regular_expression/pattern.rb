# frozen_string_literal: true

module RegularExpression
  class Pattern
    attr_reader :bytecode

    def initialize(source)
      parser = RegularExpression::Parser.new
      nfa = parser.parse(source).to_nfa

      @bytecode = RegularExpression::Bytecode.compile(nfa)
    end

    def jit!
      function = native_function

      define_singleton_method(:match?) do |string|
        function.call(string, string.size) == 1
      end      
    end

    def match?(string)
      interpreter = RegularExpression::Interpreter.new
      interpreter.match?(bytecode, string)
    end

    private

    def native_function
      builder = RegularExpression::CFG::Builder.new

      RegularExpression::Generator::Native
        .generate(builder.build(bytecode))
        .to_function([Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T], Fiddle::TYPE_SIZE_T)
    end
  end
end
