# frozen_string_literal: true

module RegularExpression
  # POSIX character types represent classes of characters that are determined by
  # the user's locale. For our purposes we're calling out to the ctype function
  # that corresponds to the type in the name that should tell us if they belong
  # in the character type. So for example if you have [[:alpha:]] in your regex,
  # here we call out to the ctype isalpha function.
  #
  # For more information about locales, see the following link:
  #
  #   https://pubs.opengroup.org/onlinepubs/9699919799/
  #
  class CharacterType
    attr_reader :type # String
    attr_reader :handle # Integer
    attr_reader :function # (Integer) -> bool

    KNOWN = %w[
      Alnum
      Alpha
      ASCII
      Blank
      Cntrl
      Digit
      Graph
      Lower
      Print
      Punct
      Space
      Upper
      XDigit
    ].freeze

    def initialize(type)
      @type = type

      # Validate that we know what this kind of character type is
      raise if KNOWN.none? { |known| known.casecmp(type).zero? }

      @handle = Fiddle::Handle::DEFAULT["is#{type}"]

      # Here we're assuming that every function that we're going to use has the
      # same (int) -> int signature.
      @function = Fiddle::Function.new(@handle, [Fiddle::TYPE_INT], Fiddle::TYPE_INT)
    end

    def match?(char)
      function.call(char.ord) != 0
    end
  end
end
