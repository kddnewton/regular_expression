# frozen_string_literal: true

module RegularExpression
  class Pattern
    attr_reader :bytecode

    #class Iflag
      #def apply(root)
        #to_process = [root]
        #processed_states = Set.new

        #while((node, transitions = to_process.pop)) do
          #transitions.map! do |transition|
            #to_process << transition.state if processed_states.exclude?(node)

            #case transition
            #end
          #end
        #end
      #end
    #end

    class Iflag
      def call(start, transition)
        case transition
        when NFA::Transition::Value
          value = transition.value
          downcase = value.downcase
          upcase = value.upcase
          if value != downcase
            start.add_transition(
              NFA::Transition::Value.new(transition.state, downcase)
            )
          end

          if value != upcase
            start.add_transition(
              NFA::Transition::Value.new(transition.state, upcase)
            )
          end
        end
      end
    end

    def initialize(source, flags="")
      ast = Parser.new.parse(source)
      @flags = flags
      @bytecode = Bytecode.compile(ast.to_nfa([Iflag.new]))
    end

    def compile(compiler: Compiler::X86)
      cfg = CFG.build(bytecode)
      schedule = Scheduler.schedule(cfg)

      singleton_class.undef_method(:match?)
      define_singleton_method(:match?, &compiler.compile(cfg, schedule))
    end

    def match?(string)
      Interpreter.new(bytecode).match?(string)
    end
  end
end
