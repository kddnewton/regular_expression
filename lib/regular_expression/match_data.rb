# frozen_string_literal: true

module RegularExpression
  # This object represents a successful match against an input string. It is
  # created using the original string that was matched against along with the
  # indices that represent the capture groups.
  #
  # Ideally this very closely mirrors that API of the top-level MatchData object
  # so that it's seemless to switch between the two.
  class MatchData
    attr_reader :captures
    alias to_a captures

    def initialize(string, indices)
      @captures = []

      indices.each_slice(2) do |start, finish|
        @captures << (start != -1 && finish != -1 ? string[start...finish] : nil)
      end
    end

    def [](index)
      captures[index]
    end
  end
end
