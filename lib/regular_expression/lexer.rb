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

    def initialize(source, flags = Flags.new)
      @scanner = StringScanner.new(source)
      @flags = flags
    end

    def tokens
      result = []

      until @scanner.eos?
        case # rubocop:disable Style/EmptyCaseCondition
        when @flags.extended? && (@scanner.scan(/\s/) || @scanner.scan(/#.+?\n/))
          # ignore whitespace in extended mode
        when !@flags.extended? && @scanner.scan(/\(\?#.+?\)/)
          # ignore this interesting comment pattern in non-extended mode
        when !@flags.multiline? && @scanner.scan(/\u0009|\u000A|\u000D/)
          # unless multiline is enabled . will not match \n
        when @scanner.scan(/\\\\/)
          result << [:CHAR, "\\"]
        when @scanner.scan(/\(\?=/)
          result << [:POSITIVE_LOOKAHEAD, @scanner.matched]
        when @scanner.scan(/\(\?!/)
          result << [:NEGATIVE_LOOKAHEAD, @scanner.matched]
        when @scanner.scan(/\(\?:/)
          result << [:NO_CAPTURE, @scanner.matched]
        when @scanner.scan(/\\[wWdDhHsS]/)
          result << [:CHAR_CLASS, @scanner.matched]
        when @scanner.scan(/\[\[:(?<type>#{CharacterType::KNOWN.map(&:downcase).join("|")}):\]\]/)
          result << [:CHAR_TYPE, @scanner[:type]]
        when @scanner.scan(/\\p\{(?<type>#{CharacterType::KNOWN.join("|")})\}/)
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
