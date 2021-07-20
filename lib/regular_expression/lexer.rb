# frozen_string_literal: true

module RegularExpression
  class Lexer
    SINGLE = {
      "^" => :CARET,
      "$" => :ENDING,
      "(" => :LPAREN,
      ")" => :RPAREN,
      "[" => :LBRACKET,
      "]" => :RBRACKET,
      "{" => :LBRACE,
      "}" => :RBRACE,
      "|" => :PIPE,
      "*" => :STAR,
      "+" => :PLUS,
      "?" => :QMARK,
      "." => :PERIOD,
      "-" => :DASH,
      "," => :COMMA
    }.freeze

    def initialize(source)
      @scanner = StringScanner.new(source)
    end

    def tokens
      result = []

      until @scanner.eos?
        case # rubocop:disable Style/EmptyCaseCondition
        when @scanner.scan(/\A\\[wWdDhs]/)
          result << [:CHAR_CLASS, @scanner.matched]
        when @scanner.scan(/\A(?:\\[Az]|\$)/)
          result << [:ANCHOR, @scanner.matched]
        when @scanner.scan(/\A[\^$()\[\]{}|*+?.\-,]/)
          result << [SINGLE[@scanner.matched], @scanner.matched]
        when @scanner.scan(/\A\d+/)
          result << [:INTEGER, @scanner.matched.to_i]
        when @scanner.scan(/\A(?:\u0009|\u000A|\u000D|[\u0020-\uD7FF]|[\uE000-\uFFFD])/)
          result << [:CHAR, @scanner.matched]
        else
          raise SyntaxError, @scanner.rest
        end
      end

      result << [false, "end"]
      result
    end
  end
end
