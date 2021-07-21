# frozen_string_literal: true

module UI
  MATCH_ICON = "check circle"
  MATCH_TEXT = "That's a match!"
  MATCH_COLOR = "teal"

  NO_MATCH_ICON = "exclamation triangle"
  NO_MATCH_TEXT = "That's not a match!"
  NO_MATCH_COLOR = "yellow"

  ERROR_ICON = "times circle"
  ERROR_TEXT = "Invalid regular expression"
  ERROR_COLOR = "red"

  class Match
    attr_reader :icon, :text, :color, :graph

    def initialize(icon: MATCH_ICON, text: MATCH_TEXT, color: MATCH_COLOR, graph: nil)
      @icon = icon
      @text = text
      @color = color
      @graph = graph
    end
  end

  ERROR = Match.new(icon: ERROR_ICON, text: ERROR_TEXT, color: ERROR_COLOR)
  NO_MATCH = Match.new(icon: NO_MATCH_ICON, text: NO_MATCH_TEXT, color: NO_MATCH_COLOR)
end
