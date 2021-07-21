#
# DO NOT MODIFY!!!!
# This file is automatically generated by Racc 1.5.2
# from Racc grammar file "".
#

require 'racc/parser.rb'
module RegularExpression
  class Parser < Racc::Parser

module_eval(<<'...end parser.y/module_eval...', 'parser.y', 131)

  def parse(str)
    @tokens = Lexer.new(str).tokens
    do_parse
  end

  def next_token
    @tokens.shift
  end
...end parser.y/module_eval...
##### State transition tables begin ###

racc_action_table = [
     3,    23,     9,    10,    25,    11,    13,    44,    14,    15,
    16,    17,    18,    19,    20,    21,    22,     9,    10,    44,
    11,    13,    46,    14,    15,    16,    17,    18,    19,    20,
    21,    22,     9,    10,    48,    11,    13,    49,    14,    15,
    16,    17,    18,    19,    20,    21,    22,     9,    10,    55,
    11,    13,    57,    14,    15,    16,    17,    18,    19,    20,
    21,    22,     9,    10,    58,    11,    13,    44,    14,    15,
    16,    17,    18,    19,    20,    21,    22,     9,    10,    60,
    11,    13,    53,    14,    15,    16,    17,    18,    19,    20,
    21,    22,    34,    37,    63,    38,    39,    51,    40,    53,
    37,    64,    38,    39,    37,    40,    38,    39,    53,    40,
    53,    67,    30,    70,    31,    32,    33,    30,    68,    31,
    32,    33,    30,    71,    31,    32,    33,    72 ]

racc_action_check = [
     0,     1,     0,     0,     5,     0,     0,    21,     0,     0,
     0,     0,     0,     0,     0,     0,     0,     3,     3,    22,
     3,     3,    23,     3,     3,     3,     3,     3,     3,     3,
     3,     3,     6,     6,    27,     6,     6,    28,     6,     6,
     6,     6,     6,     6,     6,     6,     6,    10,    10,    35,
    10,    10,    38,    10,    10,    10,    10,    10,    10,    10,
    10,    10,    11,    11,    42,    11,    11,    43,    11,    11,
    11,    11,    11,    11,    11,    11,    11,    25,    25,    45,
    25,    25,    51,    25,    25,    25,    25,    25,    25,    25,
    25,    25,    13,    34,    50,    34,    34,    30,    34,    30,
    13,    50,    13,    13,    36,    13,    36,    36,    63,    36,
    53,    54,    12,    63,    12,    12,    12,    48,    57,    48,
    48,    48,    49,    65,    49,    49,    49,    69 ]

racc_action_pointer = [
    -2,     1,   nil,    13,   nil,     1,    28,   nil,   nil,   nil,
    43,    58,    93,    90,   nil,   nil,   nil,   nil,   nil,   nil,
   nil,    -5,     7,    22,   nil,    73,   nil,    28,    31,   nil,
    84,   nil,   nil,   nil,    83,    40,    94,   nil,    38,   nil,
   nil,   nil,    58,    55,   nil,    73,   nil,   nil,    98,   103,
    81,    67,   nil,    95,   102,   nil,   nil,   106,   nil,   nil,
   nil,   nil,   nil,    93,   nil,   103,   nil,   nil,   nil,   107,
   nil,   nil,   nil ]

racc_action_default = [
    -2,   -49,    -1,   -49,    -4,    -6,    -8,    -9,   -10,   -11,
   -49,   -49,   -17,   -49,   -20,   -21,   -22,   -23,   -24,   -25,
   -26,   -49,   -49,   -49,    -3,   -49,    -7,   -49,   -49,   -16,
   -49,   -43,   -44,   -45,   -49,   -49,   -30,   -31,   -38,   -33,
   -34,   -35,   -49,   -37,   -38,   -49,    73,    -5,   -13,   -15,
   -49,   -49,   -46,   -48,   -49,   -19,   -29,   -49,   -27,   -36,
   -28,   -12,   -14,   -49,   -42,   -49,   -47,   -18,   -32,   -49,
   -40,   -41,   -39 ]

racc_goto_table = [
    29,    50,     4,    35,     1,    24,    42,    45,    43,    43,
     2,    26,    27,    28,    66,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,    65,   nil,    54,   nil,    56,    47,    59,   nil,
    43,   nil,   nil,   nil,    69,   nil,    61,    62 ]

racc_goto_check = [
     8,    14,     3,    10,     1,     3,    11,    11,    13,    13,
     2,     4,     3,     3,    15,   nil,   nil,   nil,   nil,   nil,
   nil,   nil,    14,   nil,    10,   nil,    10,     3,    11,   nil,
    13,   nil,   nil,   nil,    14,   nil,     8,     8 ]

racc_goto_pointer = [
   nil,     4,    10,     2,     5,   nil,   nil,   nil,   -12,   nil,
   -10,   -15,   nil,   -13,   -29,   -39 ]

racc_goto_default = [
   nil,   nil,   nil,   nil,     5,     6,     7,     8,   nil,    12,
   nil,   nil,    36,    41,   nil,    52 ]

racc_reduce_table = [
  0, 0, :racc_error,
  1, 25, :_reduce_1,
  0, 25, :_reduce_2,
  2, 26, :_reduce_3,
  1, 26, :_reduce_4,
  3, 27, :_reduce_5,
  1, 27, :_reduce_6,
  2, 28, :_reduce_7,
  1, 28, :_reduce_8,
  1, 29, :_reduce_none,
  1, 29, :_reduce_none,
  1, 29, :_reduce_11,
  4, 30, :_reduce_12,
  3, 30, :_reduce_13,
  4, 30, :_reduce_14,
  3, 30, :_reduce_15,
  2, 31, :_reduce_16,
  1, 31, :_reduce_17,
  4, 33, :_reduce_18,
  3, 33, :_reduce_19,
  1, 33, :_reduce_20,
  1, 33, :_reduce_21,
  1, 33, :_reduce_22,
  1, 33, :_reduce_23,
  1, 33, :_reduce_24,
  1, 33, :_reduce_25,
  1, 33, :_reduce_26,
  3, 33, :_reduce_27,
  3, 33, :_reduce_28,
  2, 34, :_reduce_29,
  1, 34, :_reduce_30,
  1, 36, :_reduce_31,
  3, 36, :_reduce_32,
  1, 36, :_reduce_33,
  1, 36, :_reduce_34,
  1, 36, :_reduce_none,
  2, 35, :_reduce_36,
  1, 35, :_reduce_37,
  1, 37, :_reduce_38,
  5, 32, :_reduce_39,
  4, 32, :_reduce_40,
  4, 32, :_reduce_41,
  3, 32, :_reduce_42,
  1, 32, :_reduce_43,
  1, 32, :_reduce_44,
  1, 32, :_reduce_45,
  1, 38, :_reduce_46,
  2, 39, :_reduce_47,
  1, 39, :_reduce_48 ]

racc_reduce_n = 49

racc_shift_n = 73

racc_token_table = {
  false => 0,
  :error => 1,
  :CARET => 2,
  :PIPE => 3,
  :ANCHOR => 4,
  :LPAREN => 5,
  :RPAREN => 6,
  :NO_CAPTURE => 7,
  :LBRACKET => 8,
  :RBRACKET => 9,
  :CHAR_CLASS => 10,
  :CHAR_TYPE => 11,
  :CHAR => 12,
  :COMMA => 13,
  :DASH => 14,
  :DIGIT => 15,
  :PERIOD => 16,
  :POSITIVE_LOOKAHEAD => 17,
  :NEGATIVE_LOOKAHEAD => 18,
  :LBRACE => 19,
  :RBRACE => 20,
  :STAR => 21,
  :PLUS => 22,
  :QMARK => 23 }

racc_nt_base = 24

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
  "LPAREN",
  "RPAREN",
  "NO_CAPTURE",
  "LBRACKET",
  "RBRACKET",
  "CHAR_CLASS",
  "CHAR_TYPE",
  "CHAR",
  "COMMA",
  "DASH",
  "DIGIT",
  "PERIOD",
  "POSITIVE_LOOKAHEAD",
  "NEGATIVE_LOOKAHEAD",
  "LBRACE",
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
  "assertion_items",
  "character_group_item",
  "character",
  "integer",
  "digits" ]

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
     result = AST::Root.new(val[1], at_start: true)
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 14)
  def _reduce_4(val, _values, result)
     result = AST::Root.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 18)
  def _reduce_5(val, _values, result)
     result = [AST::Expression.new(val[0])] + val[2]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 20)
  def _reduce_6(val, _values, result)
     result = [AST::Expression.new(val[0])]
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
     result = AST::Anchor.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 36)
  def _reduce_12(val, _values, result)
     result = AST::CaptureGroup.new(val[1], quantifier: val[3])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 38)
  def _reduce_13(val, _values, result)
     result = AST::CaptureGroup.new(val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 40)
  def _reduce_14(val, _values, result)
     result = AST::Group.new(val[1], quantifier: val[3])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 42)
  def _reduce_15(val, _values, result)
     result = AST::Group.new(val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 46)
  def _reduce_16(val, _values, result)
     result = AST::Match.new(val[0], quantifier: val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 48)
  def _reduce_17(val, _values, result)
     result = AST::Match.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 52)
  def _reduce_18(val, _values, result)
     result = AST::CharacterGroup.new(val[2], invert: true)
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 54)
  def _reduce_19(val, _values, result)
     result = AST::CharacterGroup.new(val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 56)
  def _reduce_20(val, _values, result)
     result = AST::CharacterClass.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 58)
  def _reduce_21(val, _values, result)
     result = AST::CharacterType.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 60)
  def _reduce_22(val, _values, result)
     result = AST::Character.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 62)
  def _reduce_23(val, _values, result)
     result = AST::Character.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 64)
  def _reduce_24(val, _values, result)
     result = AST::Character.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 66)
  def _reduce_25(val, _values, result)
     result = AST::Character.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 68)
  def _reduce_26(val, _values, result)
     result = AST::Period.new
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 70)
  def _reduce_27(val, _values, result)
     result = AST::PositiveLookahead.new(val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 72)
  def _reduce_28(val, _values, result)
     result = AST::NegativeLookahead.new(val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 76)
  def _reduce_29(val, _values, result)
     result = [val[0]] + val[1]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 78)
  def _reduce_30(val, _values, result)
     result = [val[0]]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 82)
  def _reduce_31(val, _values, result)
     result = AST::CharacterClass.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 84)
  def _reduce_32(val, _values, result)
     result = AST::CharacterRange.new(val[0], val[2])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 86)
  def _reduce_33(val, _values, result)
     result = AST::Character.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 88)
  def _reduce_34(val, _values, result)
     result = AST::Character.new(val[0])
    result
  end
.,.,

# reduce 35 omitted

module_eval(<<'.,.,', 'parser.y', 93)
  def _reduce_36(val, _values, result)
     result = [val[0]] + val[1]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 95)
  def _reduce_37(val, _values, result)
     result = [val[0]]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 99)
  def _reduce_38(val, _values, result)
     result = AST::Character.new(val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 103)
  def _reduce_39(val, _values, result)
     result = AST::Quantifier::Range.new(val[1], val[3])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 105)
  def _reduce_40(val, _values, result)
     result = AST::Quantifier::AtLeast.new(val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 107)
  def _reduce_41(val, _values, result)
     result = AST::Quantifier::Range.new(0, val[2])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 109)
  def _reduce_42(val, _values, result)
     result = AST::Quantifier::Exact.new(val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 111)
  def _reduce_43(val, _values, result)
     result = AST::Quantifier::ZeroOrMore.new
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 113)
  def _reduce_44(val, _values, result)
     result = AST::Quantifier::OneOrMore.new
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 115)
  def _reduce_45(val, _values, result)
     result = AST::Quantifier::Optional.new
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 119)
  def _reduce_46(val, _values, result)
     result = val[0].to_i
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 123)
  def _reduce_47(val, _values, result)
     result = val[0] + val[1]
    result
  end
.,.,

module_eval(<<'.,.,', 'parser.y', 125)
  def _reduce_48(val, _values, result)
     result = val[0]
    result
  end
.,.,

def _reduce_none(val, _values, result)
  val[0]
end

  end   # class Parser
end   # module RegularExpression
