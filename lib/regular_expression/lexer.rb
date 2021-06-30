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
    }

    def initialize(source)
      @source = source.dup
    end

    def tokens
      result = []

      until @source.empty?
        case @source
        when /\A\(\?:/
          result << [:NO_CAPTURE, $&]
        when /\A\\[wWdD]/
          result << [:CHAR_CLASS, $&]
        when /\A(?:\\[bBAzZG]|\$)/
          result << [:ANCHOR, $&]
        when /\A[\^$()\[\]{}|*+?.\-,]/
          result << [SINGLE[$&], $&]
        when /\A\d+/
          result << [:INTEGER, $&.to_i]
        when /\A(?:\u0009|\u000A|\u000D|[\u0020-\uD7FF]|[\uE000-\uFFFD]|[\u100000-\u10FFFF])/
          result << [:CHAR, $&]
        else
          raise SyntaxError, @source
        end

        @source = $'
      end

      result << [false, "end"]
      result
    end
  end
end
