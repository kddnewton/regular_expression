# frozen_string_literal: true

module RegularExpression
  module Flags
    class Base
      def call(start, transition); end
    end

    class Iflag < Base
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

    FLAGS = {
      "i" => Iflag.new
    }

    def self.parse(flags = "")
      if flags == ""
        [Base.new]
      else
        flags.split('').map do |flag|
          FLAGS[flag]
        end.compact
      end
    end
  end
end
