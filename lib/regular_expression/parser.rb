#
# DO NOT MODIFY!!!!
# This file is automatically generated by Racc 1.5.2
# from Racc grammar file "".
#

require 'racc/parser.rb'
module RegularExpression
  class Parser < Racc::Parser

module_eval(<<'...end parser.y/module_eval...', 'parser.y', 92)
  
  def parse(str)
    @tokens = RegularExpression::Lexer.new(str).tokens
    do_parse
  end

  def next_token
    @tokens.shift
  end
...end parser.y/module_eval...
##### State transition tables begin ###

racc_action_table = [
     3,    17,     9,    10,    28,    11,    13,    19,    14,    15,
    16,    33,    31,    32,     9,    10,    35,    11,    13,    36,
    14,    15,    16,     9,    10,    37,    11,    13,    39,    14,
    15,    16,     9,    10,    41,    11,    13,    46,    14,    15,
    16,     9,    10,    47,    11,    13,    50,    14,    15,    16,
     9,    10,   nil,    11,    13,    24,    14,    15,    16,    25,
    26,    27,    24,    31,    32,    24,    25,    26,    27,    25,
    26,    27,    48,   nil,    49,    31,    32,    44,    45 ]

racc_action_check = [
     0,     1,     0,     0,    13,     0,     0,     5,     0,     0,
     0,    17,    13,    13,     3,     3,    21,     3,     3,    22,
     3,     3,     3,     6,     6,    24,     6,     6,    29,     6,
     6,     6,    10,    10,    32,    10,    10,    38,    10,    10,
    10,    11,    11,    41,    11,    11,    48,    11,    11,    11,
    19,    19,   nil,    19,    19,    12,    19,    19,    19,    12,
    12,    12,    35,    28,    28,    36,    35,    35,    35,    36,
    36,    36,    44,   nil,    44,    30,    30,    37,    37 ]

racc_action_pointer = [
    -2,     1,   nil,    10,   nil,     4,    19,   nil,   nil,   nil,
    28,    37,    41,     2,   nil,   nil,   nil,    11,   nil,    46,
   nil,    10,    13,   nil,    10,   nil,   nil,   nil,    53,    19,
    65,   nil,    21,   nil,   nil,    48,    51,    61,    28,   nil,
   nil,    32,   nil,   nil,    57,   nil,   nil,   nil,    29,   nil,
   nil ]

racc_action_default = [
    -2,   -34,    -1,   -34,    -4,    -6,    -8,    -9,   -10,   -11,
   -34,   -34,   -17,   -34,   -20,   -21,   -22,   -34,    -3,   -34,
    -7,   -34,   -34,   -16,   -34,   -31,   -32,   -33,   -34,   -34,
   -24,   -25,   -27,    51,    -5,   -13,   -15,   -34,   -34,   -19,
   -23,   -34,   -12,   -14,   -34,   -30,   -18,   -26,   -34,   -29,
   -28 ]

racc_goto_table = [
    23,     4,    29,     1,    18,     2,    20,   nil,   nil,   nil,
   nil,    21,    22,   nil,   nil,   nil,   nil,    38,   nil,    40,
    34,   nil,   nil,    42,    43 ]

racc_goto_check = [
     8,     3,    10,     1,     3,     2,     4,   nil,   nil,   nil,
   nil,     3,     3,   nil,   nil,   nil,   nil,    10,   nil,    10,
     3,   nil,   nil,     8,     8 ]

racc_goto_pointer = [
   nil,     3,     5,     1,     0,   nil,   nil,   nil,   -12,   nil,
   -11,   nil ]

racc_goto_default = [
   nil,   nil,   nil,   nil,     5,     6,     7,     8,   nil,    12,
   nil,    30 ]

racc_reduce_table = [
  0, 0, :racc_error,
  1, 22, :_reduce_1,
  0, 22, :_reduce_2,
  2, 23, :_reduce_3,
  1, 23, :_reduce_4,
  3, 24, :_reduce_5,
  1, 24, :_reduce_6,
  2, 25, :_reduce_7,
  1, 25, :_reduce_8,
  1, 26, :_reduce_none,
  1, 26, :_reduce_none,
  1, 26, :_reduce_11,
  4, 27, :_reduce_12,
  3, 27, :_reduce_13,
  4, 27, :_reduce_14,
  3, 27, :_reduce_15,
  2, 28, :_reduce_16,
  1, 28, :_reduce_17,
  4, 30, :_reduce_18,
  3, 30, :_reduce_19,
  1, 30, :_reduce_20,
  1, 30, :_reduce_21,
  1, 30, :_reduce_22,
  2, 31, :_reduce_23,
  1, 31, :_reduce_24,
  1, 32, :_reduce_none,
  3, 32, :_reduce_26,
  1, 32, :_reduce_27,
  5, 29, :_reduce_28,
  4, 29, :_reduce_29,
  3, 29, :_reduce_30,
  1, 29, :_reduce_31,
  1, 29, :_reduce_32,
  1, 29, :_reduce_33 ]

racc_reduce_n = 34

racc_shift_n = 51

racc_token_table = {
  false => 0,
  :error => 1,
  :CARET => 2,
  :PIPE => 3,
  :ANCHOR => 4,
  :NO_CAPTURE => 5,
  :RPAREN => 6,
  :LPAREN => 7,
  :LBRACKET => 8,
  :RBRACKET => 9,
  :CHAR_CLASS => 10,
  :CHAR => 11,
  :PERIOD => 12,
  :DASH => 13,
  :LBRACE => 14,
  :INTEGER => 15,
  :COMMA => 16,
  :RBRACE => 17,
  :STAR => 18,
  :PLUS => 19,
  :QMARK => 20 }

racc_nt_base = 21

racc_use_result_var = true

Racc_arg = [
  racc_action_table,
  racc_action_check,
  racc_action_default,
  racc_action_pointer,
  racc_goto_table,
  racc_goto_check,
  racc_goto_default,
  racc_goto_pointer,
  racc_nt_base,
  racc_reduce_table,
  racc_token_table,
  racc_shift_n,
  racc_reduce_n,
  racc_use_result_var ]

Racc_token_to_s_table = [
  "$end",
  "error",
  "CARET",
  "PIPE",
  "ANCHOR",
  "NO_CAPTURE",
  "RPAREN",
  "LPAREN",
  "LBRACKET",
  "RBRACKET",
  "CHAR_CLASS",
  "CHAR",
  "PERIOD",
  "DASH",
  "LBRACE",
  "INTEGER",
  "COMMA",
  "RBRACE",
  "STAR",
  "PLUS",
  "QMARK",
  "$start",
  "target",
  "root",
  "expression",
  "subexpression",
  "item",
  "group",
  "match",
  "quantifier",
  "match_item",
  "character_group_items",
  "character_group_item" ]

Racc_debug_parser = false

##### State transition tables end #####

# reduce 0 omitted

module_eval(<<'.,.,', 'parser.y', 6)
  def _reduce_1(val, _values, result)
     result = val[0]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 8)
  def _reduce_2(val, _values, result)
     result = nil
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 12)
  def _reduce_3(val, _values, result)
     result = RegularExpression::AST::Root.new(val[1], at_start: true)
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 14)
  def _reduce_4(val, _values, result)
     result = RegularExpression::AST::Root.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 18)
  def _reduce_5(val, _values, result)
     result = [RegularExpression::AST::Expression.new(val[0])] + val[2]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 20)
  def _reduce_6(val, _values, result)
     result = [RegularExpression::AST::Expression.new(val[0])]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 24)
  def _reduce_7(val, _values, result)
     result = [val[0]] + val[1]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 26)
  def _reduce_8(val, _values, result)
     result = [val[0]]
    result
  end
.,.,

# reduce 9 omitted

# reduce 10 omitted

module_eval(<<'.,.,', 'parser.y', 32)
  def _reduce_11(val, _values, result)
     result = RegularExpression::AST::Anchor.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 36)
  def _reduce_12(val, _values, result)
     result = RegularExpression::AST::Group.new(val[1], quantifier: val[3], capture: false)
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 38)
  def _reduce_13(val, _values, result)
     result = RegularExpression::AST::Group.new(val[1], capture: false)
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 40)
  def _reduce_14(val, _values, result)
     result = RegularExpression::AST::Group.new(val[1], quantifier: val[3])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 42)
  def _reduce_15(val, _values, result)
     result = RegularExpression::AST::Group.new(val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 46)
  def _reduce_16(val, _values, result)
     result = RegularExpression::AST::Match.new(val[0], quantifier: val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 48)
  def _reduce_17(val, _values, result)
     result = RegularExpression::AST::Match.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 52)
  def _reduce_18(val, _values, result)
     result = RegularExpression::AST::CharacterGroup.new(val[2], invert: true)
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 54)
  def _reduce_19(val, _values, result)
     result = RegularExpression::AST::CharacterGroup.new(val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 56)
  def _reduce_20(val, _values, result)
     result = RegularExpression::AST::CharacterClass.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 58)
  def _reduce_21(val, _values, result)
     result = RegularExpression::AST::Character.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 60)
  def _reduce_22(val, _values, result)
     result = RegularExpression::AST::Period.new
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 64)
  def _reduce_23(val, _values, result)
     result = [val[0]] + val[1]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 66)
  def _reduce_24(val, _values, result)
     result = [val[0]]
    result
  end
.,.,

# reduce 25 omitted

module_eval(<<'.,.,', 'parser.y', 71)
  def _reduce_26(val, _values, result)
     result = RegularExpression::AST::CharacterRange.new(val[0], val[2])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 73)
  def _reduce_27(val, _values, result)
     result = RegularExpression::AST::Character.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 77)
  def _reduce_28(val, _values, result)
     result = RegularExpression::AST::Quantifier::Range.new(val[1], val[3])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 79)
  def _reduce_29(val, _values, result)
     result = RegularExpression::AST::Quantifier::AtLeast.new(val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 81)
  def _reduce_30(val, _values, result)
     result = RegularExpression::AST::Quantifier::Exact.new(val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 83)
  def _reduce_31(val, _values, result)
     result = RegularExpression::AST::Quantifier::ZeroOrMore.new
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 85)
  def _reduce_32(val, _values, result)
     result = RegularExpression::AST::Quantifier::OneOrMore.new
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 87)
  def _reduce_33(val, _values, result)
     result = RegularExpression::AST::Quantifier::Optional.new
    result
  end
.,.,

def _reduce_none(val, _values, result)
  val[0]
end

  end   # class Parser
end   # module RegularExpression
