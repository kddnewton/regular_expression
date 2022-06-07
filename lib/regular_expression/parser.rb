# frozen_string_literal: true

module RegularExpression
  # This object is responsible for turning a source string into an AST::Pattern
  # node.
  class Parser
    # We build a custom enumerator here to make it easier to rollback to a
    # specific point. This is necessary to support arbitrary lookahead.
    class Lexer
      attr_reader :tokens, :cached, :index

      def initialize(source)
        @tokens = make_tokens(source)
        @cached = []
        @index = 0
      end

      def next
        cached << tokens.next if index == cached.length
        result = cached[index]

        @index += 1
        result
      end

      def peek
        index == cached.length ? tokens.peek : cached[index]
      end

      private

      # This walks through the source of the regular expression and yields each
      # lexical token (AST::Token) it finds in the source back to an enumerator.
      def make_tokens(source)
        Enumerator.new do |enum|
          index = 0

          while index < source.length
            type =
              case source[index..]
              in /\A\./ then :dot
              in /\A\*/ then :star
              in /\A\+/ then :plus
              in /\A\?/ then :qmark
              in /\A\|/ then :pipe
              in /\A\{/ then :lbrace
              in /\A\}/ then :rbrace
              in /\A\(/ then :lparen
              in /\A\)/ then :rparen
              in /\A./  then :char
              end

            location = AST::Location[index...(index + $&.length)]
            enum << AST::Token.new(type: type, value: $&, location: location)
            index += $&.length
          end

          location = AST::Location[index...index]
          enum << AST::Token.new(type: :EOF, value: nil, location: location)
        end
      end
    end

    attr_reader :source, :flags

    def initialize(source, flags = Flags.new)
      @source = source
      @flags = flags
    end

    # This parses the regular expression and returns an AST::Pattern node.
    def parse
      parse_pattern(Lexer.new(source))
    end

    private

    # This creates an AST::Pattern object that is the root of the AST. It parses
    # each expression in turn, then gathers them up together.
    def parse_pattern(tokens)
      expressions = [parse_expression(tokens)]

      while tokens.peek in { type: :pipe }
        tokens.next
        expressions << parse_expression(tokens)
      end

      tokens.next => { type: :EOF }
      location = AST::Location[0...source.length]
      AST::Pattern.new(expressions: expressions, location: location)
    end

    # This creates an AST::Expression object that contains a list of items to
    # match in sequence.
    def parse_expression(tokens)
      items = []
      items << parse_item(tokens) until (tokens.peek in { type: :pipe | :EOF | :rparen })

      location =
        if items.any?
          items.first.location.to(items.last.location)
        else
          tokens.peek.location
        end

      AST::Expression.new(items: items, location: location)
    end

    # This creates an AST::MatchCharacter or AST::Quantified object that
    # represents an item within an expression to match.
    def parse_item(tokens)
      item =
        case tokens.peek
        in { type: :char, value:, location: }
          tokens.next
          AST::MatchCharacter.new(value: value, location: location)
        in { type: :dot, location: }
          tokens.next
          AST::MatchAny.new(location: location)
        in { type: :lparen }
          parse_group(tokens)
        end

      if (quantifier = maybe_parse_quantifier(tokens))
        item =
          AST::Quantified.new(
            item: item,
            quantifier: quantifier,
            location: item.location.to(quantifier.location)
          )
      end

      item
    end

    # This creates an AST::Group object that contains a list of expressions to
    # match.
    def parse_group(tokens)
      start = tokens.next
      start => { type: :lparen }

      expressions = []

      loop do
        case tokens.peek
        in { type: :rparen }
          break
        in { type: :pipe }
          tokens.next
        else
          expressions << parse_expression(tokens)
        end
      end

      tokens.peek => { type: :rparen }
      location = start.location.to(tokens.next.location)
      AST::Group.new(expressions: expressions, location: location)
    end

    # This creates an AST::StarQuantifier object if the next token is a star,
    # otherwise it will return nil.
    def maybe_parse_quantifier(tokens)
      case tokens.peek
      in { type: :star, location: }
        tokens.next
        AST::StarQuantifier.new(location: location)
      in { type: :plus, location: }
        tokens.next
        AST::PlusQuantifier.new(location: location)
      in { type: :qmark, location: }
        tokens.next
        AST::OptionalQuantifier.new(location: location)
      in { type: :lbrace, location: start_location }
        tokens.next

        digits = []
        location = start_location

        loop do
          case tokens.next
          in { type: :rbrace, location: end_location }
            location = start_location.to(end_location)
            break
          in { type: :char, value: /\d/ => value }
            digits << value
          end
        end

        value = digits.join.to_i
        AST::RangeQuantifier.new(minimum: value, maximum: value, location: location)
      else
      end
    end
  end
end
