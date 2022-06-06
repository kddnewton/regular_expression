# frozen_string_literal: true

module RegularExpression
  # This module contains classes that make up the syntax tree representation of
  # the regular expression.
  module AST
    # This represents a location in the source string where tokens and nodes
    # occur.
    class Location
      attr_reader :start_char, :end_char

      def initialize(start_char:, end_char:)
        @start_char = start_char
        @end_char = end_char
      end

      def to(other)
        Location.new(start_char: start_char, end_char: other.end_char)
      end

      def self.[](range)
        new(start_char: range.begin, end_char: range.end)
      end
    end

    # A parsed token from the source. It contains a type, the value of the
    # token, and the location in the source.
    class Token
      attr_reader :type, :value, :location

      def initialize(type:, value:, location:)
        @type = type
        @value = value
        @location = location
      end

      def deconstruct_keys(keys)
        { type: type, value: value, location: location }
      end
    end

    # This is a visitor class that understands how to walk down the AST.
    class Visitor
      def visit(node)
        node&.accept(self)
      end

      def visit_all(nodes)
        nodes.map { |node| visit(node) }
      end

      def visit_child_nodes(node)
        visit_all(node.child_nodes)
      end

      # Visit an Expression node.
      alias visit_expression visit_child_nodes

      # Visit a MatchAny node.
      alias visit_match_any visit_child_nodes

      # Visit a MatchCharacter node.
      alias visit_match_character visit_child_nodes

      # Visit a Pattern node.
      alias visit_pattern visit_child_nodes

      # Visit a PlusQuantifier node.
      alias visit_plus_quantifier visit_child_nodes

      # Visit a Quantified node.
      alias visit_quantified visit_child_nodes

      # Visit a StarQuantifier node.
      alias visit_star_quantifier visit_child_nodes
    end

    # This is a visitor that will walk the tree and pretty-print the AST.
    class PrettyPrintVisitor < Visitor
      attr_reader :q

      def initialize(q)
        @q = q
      end

      # Visit an Expression node.
      def visit_expression(node)
        token("expression") do
          q.breakable
          q.seplist(node.items) { |item| q.pp(item) }
        end
      end

      # Visit a MatchAny node.
      def visit_match_any(node)
        token("match-any")
      end

      # Visit a MatchCharacter node.
      def visit_match_character(node)
        token("match-character") do
          q.breakable
          q.pp(node.value)
        end
      end

      # Visit a Pattern node.
      def visit_pattern(node)
        token("pattern") do
          q.breakable
          q.seplist(node.expressions) { |expression| q.pp(expression) }
        end
      end

      # Visit a PlusQuantifier node.
      def visit_plus_quantifier(node)
        token("plus-quantifier")
      end

      # Visit a Quantified node.
      def visit_quantified(node)
        token("quantified") do
          q.breakable
          q.pp(node.item)

          q.breakable
          q.pp(node.quantifier)
        end
      end

      # Visit a StarQuantifier node.
      def visit_star_quantifier(node)
        token("star-quantifier")
      end

      private

      def token(name)
        q.group do
          q.text("(#{name}")

          if block_given?
            q.nest(2) { yield }
            q.breakable("")
          end

          q.text(")")
        end
      end
    end

    # This is the parent class of all of the nodes in the AST.
    class Node
      def pretty_print(q)
        PrettyPrintVisitor.new(q).visit(self)
      end
    end

    # This is the root node of the AST. It contains a list of all of the
    # expressions that make up the regexp.
    class Pattern < Node
      attr_reader :expressions, :location

      def initialize(expressions:, location:)
        @expressions = expressions
        @location = location
      end

      def accept(visitor)
        visitor.visit_pattern(self)
      end

      def child_nodes
        expressions
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { expressions: expressions, location: location }
      end
    end

    # This contains a list of items that will be matched. Notably it does not
    # contain alternations (|), as that would be another expression node.
    class Expression < Node
      attr_reader :items, :location

      def initialize(items:, location:)
        @items = items
        @location = location
      end

      def accept(visitor)
        visitor.visit_expression(self)
      end

      def child_nodes
        items
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { items: items, location: location }
      end
    end

    # This is a quantifier that indicates that the item should be matched one
    # or more times.
    class PlusQuantifier < Node
      attr_reader :location

      def initialize(location:)
        @location = location
      end

      def accept(visitor)
        visitor.visit_plus_quantifier(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end
    end

    # This is a quantified item. It contains the item that needs to be matched
    # as well as the quantifier that describes how many times it should be
    # matched.
    class Quantified < Node
      attr_reader :item, :quantifier, :location

      def initialize(item:, quantifier:, location:)
        @item = item
        @quantifier = quantifier
        @location = location
      end

      def accept(visitor)
        visitor.visit_quantified(self)
      end

      def child_nodes
        [item, quantifier]
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { item: item, quantifier: quantifier, location: location }
      end
    end

    # This is a quantifier that indicates that the item should be matched zero
    # or more times.
    class StarQuantifier < Node
      attr_reader :location

      def initialize(location:)
        @location = location
      end

      def accept(visitor)
        visitor.visit_star_quantifier(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end
    end

    # This will match any given value in the input string.
    class MatchAny < Node
      attr_reader :location

      def initialize(location:)
        @location = location
      end

      def accept(visitor)
        visitor.visit_match_any(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { location: location }
      end
    end

    # This is a single character that must be matched.
    class MatchCharacter < Node
      attr_reader :value, :location

      def initialize(value:, location:)
        @value = value
        @location = location
      end

      def accept(visitor)
        visitor.visit_match_character(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, location: location }
      end
    end
  end
end
