# frozen_string_literal: true

module RegularExpression
  class Lexer
    SINGLE = {
      "^" => :CARET,
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
        when @scanner.scan(/\\\\/)
          result << [:CHAR, "\\"]
        when @scanner.scan(/\(\?=/)
          result << [:PLA, @scanner.matched]
        when @scanner.scan(/\\[wWdDhHsS]/)
          result << [:CHAR_CLASS, @scanner.matched]
        when @scanner.scan(/\[\[:(?<type>alnum|alpha|lower|upper):\]\]/)
          result << [:CHAR_TYPE, @scanner[:type]]
        when @scanner.scan(/\\p\{(?<type>Alnum|Alpha|Lower|Upper)\}/)
          result << [:CHAR_TYPE, @scanner[:type].downcase]
        when @scanner.scan(/\\[Az]|\$/)
          result << [:ANCHOR, @scanner.matched]
        when @scanner.scan(/\\./)
          result << [:CHAR, @scanner.matched[-1]]
        when @scanner.scan(/[()\[\]{}^$|*+?.,-]/)
          result << [SINGLE[@scanner.matched], @scanner.matched]
        when @scanner.scan(/\d/)
          result << [:DIGIT, @scanner.matched]
        when @scanner.scan(/\u0009|\u000A|\u000D|[\u0020-\uD7FF]|[\uE000-\uFFFD]/)
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
