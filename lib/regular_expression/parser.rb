# frozen_string_literal: true

module RegularExpression
  # This object is responsible for turning a source string into an AST::Pattern
  # node.
  class Parser
    attr_reader :source, :flags

    def initialize(source, flags)
      @source = source
      @flags = flags
    end

    # This parses the regular expression and returns an AST::Pattern node.
    def parse
      parse_pattern(each_token)
    end

    private

    # This walks through the source of the regular expression and yields each
    # lexical token (AST::Token) it finds in the source back to an enumerator.
    def each_token
      Enumerator.new do |enum|
        index = 0

        while index < source.length
          type =
            case source[index..]
            in /\A\./ then :dot
            in /\A\*/ then :star
            in /\A\|/ then :pipe
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
      items << parse_item(tokens) until (tokens.peek in { type: :pipe | :EOF })

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
        case tokens.next
        in { type: :char, value:, location: }
          AST::MatchCharacter.new(value: value, location: location)
        in { type: :dot, location: }
          AST::MatchAny.new(location: location)
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

    # This creates an AST::StarQuantifier object if the next token is a star,
    # otherwise it will return nil.
    def maybe_parse_quantifier(tokens)
      if tokens.peek in { type: :star, location: }
        tokens.next
        AST::StarQuantifier.new(location: location)
      end
    end
  end
end
