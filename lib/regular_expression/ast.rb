# frozen_string_literal: true

module RegularExpression
  module AST
    class Root
      # Expression[]
      attr_reader :expressions

      # bool
      attr_reader :at_start

      def initialize(expressions, at_start: false)
        @expressions = expressions
        @at_start = at_start
      end
    end

    class Expression
      # Group | Match | Anchor
      attr_reader :items

      def initialize(items)
        @items = items
      end
    end

    class Group
      # Expression[]
      attr_reader :expressions

      # Quantifier?
      attr_reader :quantifier
    
      # bool
      attr_reader :capture

      def initialize(expressions, quantifier: nil, capture: true)
        @expressions = expressions
        @quantifier = quantifier
        @capture = capture
      end
    end

    class Match
      # CharacterGroup | CharacterClass | Character | Period
      attr_reader :item

      # Quantifier?
      attr_reader :quantifier

      def initialize(item, quantifier: nil)
        @item = item
        @quantifier = quantifier
      end
    end

    class CharacterGroup
      # (CharacterRange | Character)[]
      attr_reader :items

      # bool
      attr_reader :invert

      def initialize(items, invert: false)
        @items = items
        @invert = invert
      end
    end

    class CharacterClass
      # "\w" | "\W" | "\d" | "\D"
      attr_reader :value

      def initialize(value)
        @value = value
      end
    end

    class Character
      # string
      attr_reader :value

      def initialize(value)
        @value = value
      end
    end

    class Period
    end

    class CharacterRange
      # string
      attr_reader :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end
    end

    class Anchor
      # "\b" | "\B" | "\A" | "\z" | "\Z" | "\G" | "$"
      attr_reader :value

      def initialize(value)
        @value = value
      end
    end

    class Quantifier
      ZeroOrMore = Class.new
      OneOrMore = Class.new
      Optional = Class.new

      Exact = Struct.new(:value)
      AtLeast = Struct.new(:value)
      Range = Struct.new(:lower, :upper)

      # ZeroOrMore | OneOrMore | Optional | Exact | AtLeast | Range
      attr_reader :type

      # bool
      attr_reader :greedy

      def initialize(type, greedy: true)
        @type = type
        @greedy = greedy
      end
    end
  end
end
