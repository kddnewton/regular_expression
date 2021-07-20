# frozen_string_literal: true

class RegularExpression::Parser
rule
  target:
    root
    { result = val[0] }
    | /* none */
    { result = nil }

  root:
    CARET expression
    { result = RegularExpression::AST::Root.new(val[1], at_start: true) }
    | expression
    { result = RegularExpression::AST::Root.new(val[0]) }

  expression:
    subexpression PIPE expression
    { result = [RegularExpression::AST::Expression.new(val[0])] + val[2] }
    | subexpression
    { result = [RegularExpression::AST::Expression.new(val[0])] }

  subexpression:
    item subexpression
    { result = [val[0]] + val[1] }
    | item
    { result = [val[0]] }

  item:
    group
    | match
    | ANCHOR
    { result = RegularExpression::AST::Anchor.new(val[0]) }

  group:
    LPAREN expression RPAREN quantifier
    { result = RegularExpression::AST::Group.new(val[1], quantifier: val[3]) }
    | LPAREN expression RPAREN
    { result = RegularExpression::AST::Group.new(val[1]) }

  match:
    match_item quantifier
    { result = RegularExpression::AST::Match.new(val[0], quantifier: val[1]) }
    | match_item
    { result = RegularExpression::AST::Match.new(val[0]) }

  match_item:
    LBRACKET CARET character_group_items RBRACKET
    { result = RegularExpression::AST::CharacterGroup.new(val[2], invert: true) }
    | LBRACKET character_group_items RBRACKET
    { result = RegularExpression::AST::CharacterGroup.new(val[1]) }
    | CHAR_CLASS
    { result = RegularExpression::AST::CharacterClass.new(val[0]) }
    | CHAR
    { result = RegularExpression::AST::Character.new(val[0]) }
    | PERIOD
    { result = RegularExpression::AST::Period.new }

  character_group_items:
    character_group_item character_group_items
    { result = [val[0]] + val[1] }
    | character_group_item
    { result = [val[0]] }

  character_group_item:
    CHAR_CLASS
    | CHAR DASH CHAR
    { result = RegularExpression::AST::CharacterRange.new(val[0], val[2]) }
    | CHAR
    { result = RegularExpression::AST::Character.new(val[0]) }

  quantifier:
    LBRACE INTEGER COMMA INTEGER RBRACE
    { result = RegularExpression::AST::Quantifier::Range.new(val[1], val[3]) }
    | LBRACE INTEGER COMMA RBRACE
    { result = RegularExpression::AST::Quantifier::AtLeast.new(val[1]) }
    | LBRACE COMMA INTEGER RBRACE
    { result = RegularExpression::AST::Quantifier::Range.new(0, val[2]) }
    | LBRACE INTEGER RBRACE
    { result = RegularExpression::AST::Quantifier::Exact.new(val[1]) }
    | STAR
    { result = RegularExpression::AST::Quantifier::ZeroOrMore.new }
    | PLUS
    { result = RegularExpression::AST::Quantifier::OneOrMore.new }
    | QMARK
    { result = RegularExpression::AST::Quantifier::Optional.new }
end

---- inner
  
  def parse(str)
    @tokens = RegularExpression::Lexer.new(str).tokens
    do_parse
  end

  def next_token
    @tokens.shift
  end
