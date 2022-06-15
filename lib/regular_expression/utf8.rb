# frozen_string_literal: true

module RegularExpression
  module UTF8
    # Below is a table representing how a codepoint is represented in UTF-8.
    # We'll use this to encode the byte sequence into the state transitions
    # so that we can just compare one byte at a time.
    #
    # +-----------+------------+----------+----------+----------+----------+
    # | Minimum   | Maximum    | Byte 1   | Byte 2   | Byte 3   | Byte 4   |
    # +-----------+------------+----------+----------+----------+----------+
    # | \u{0000}  | \u{007F}   | 0xxxxxxx	|          |          |          |
    # | \u{0080}  | \u{07FF}   | 110xxxxx | 10xxxxxx |          |          |
    # | \u{0800}  | \u{FFFF}   | 1110xxxx | 10xxxxxx | 10xxxxxx	|          |
    # | \u{10000} | \u{10FFFF} | 11110xxx | 10xxxxxx | 10xxxxxx | 10xxxxxx |
    # +-----------+------------+----------+----------+----------+----------+
    class Encoder
      BYTES1_RANGE = 0x0000..0x007F
      BYTES2_RANGE = 0x0080..0x07FF
      BYTES3_RANGE = 0x0800..0xFFFF
      BYTES4_RANGE = 0x10000..0x10FFFF

      attr_reader :connector

      def initialize(connector)
        @connector = connector
      end

      def connect_range(range)
        connect_bytes1(range) if ranges_overlap?(range, BYTES1_RANGE)
        connect_bytes2(range) if ranges_overlap?(range, BYTES2_RANGE)
        connect_bytes3(range) if ranges_overlap?(range, BYTES3_RANGE)
        connect_bytes4(range) if ranges_overlap?(range, BYTES4_RANGE)
      end

      def connect_any
        connect_bytes1(BYTES1_RANGE)
        connect_bytes2(BYTES2_RANGE)
        connect_bytes3(BYTES3_RANGE)
        connect_bytes4(BYTES4_RANGE)
      end

      private

      # This is just a sanity check. When we're stepping through the possible
      # range of codepoints to encode into the state machine, we step in
      # increments that maintain the same leading bytes. We do this so we can
      # minimize the number of transitions that we are adding to the state
      # machine.
      def assert_equal_leading_bytes(bytes1, bytes2)
        bytes1[0...-1].zip(bytes2[0...-1]).each do |(left, right)|
          raise if left != right
        end
      end

      # Check if two ranges overlap. Used to determine if we need to add
      # transitions between states for a given range of codepoints.
      def ranges_overlap?(left, right)
        left.begin <= right.end && right.begin <= left.end
      end

      # Check if a range entirely encapsulates another range. If it does, we can
      # usually shortcut doing further subdivision of the range.
      def range_encapsulates?(outer, inner)
        outer.begin <= inner.begin && outer.end >= inner.end
      end

      # Connect the states for values that fall within the range that would be
      # encoded with a single byte.
      def connect_bytes1(range)
        connector.connect_range(
          connector.from,
          connector.to,
          [BYTES1_RANGE.begin, range.begin].max..[BYTES1_RANGE.end, range.end].min
        )
      end

      # # 110xxxxx 10xxxxxx
      def encode_bytes2(codepoint)
        [
          ((codepoint >> 6) & 0b11111) | 0b11000000,
          (codepoint & 0b111111) | 0b10000000
        ]
      end

      # Connect the states for values that fall within the range that would be
      # encoded with two bytes.
      def connect_bytes2(range)
        # We can shortcut if the range entirely encapsulates the potential range
        # of codepoints that can be encoded with two bytes.
        if range_encapsulates?(range, BYTES2_RANGE)
          min_bytes = encode_bytes2(BYTES2_RANGE.begin)
          max_bytes = encode_bytes2(BYTES2_RANGE.end)

          byte1 = connector.state
          connector.connect_range(connector.from, byte1, min_bytes[0]..max_bytes[0])
          connector.connect_range(byte1, connector.to, min_bytes[1]..max_bytes[1])
          return
        end

        byte1_step = 1 << 6

        BYTES2_RANGE.begin.step(BYTES2_RANGE.end, byte1_step) do |step_min|
          step_max = step_min + byte1_step - 1

          if ranges_overlap?(range, step_min..step_max)
            min_bytes = encode_bytes2([step_min, range.begin].max)
            max_bytes = encode_bytes2([step_max, range.end].min)
            assert_equal_leading_bytes(min_bytes, max_bytes)

            byte1 = connector.state
            connector.connect_range(connector.from, byte1, min_bytes[0]..max_bytes[0])
            connector.connect_range(byte1, connector.to, min_bytes[1]..max_bytes[1])
          end
        end
      end

      # 1110xxxx 10xxxxxx 10xxxxxx
      def encode_bytes3(codepoint)
        [
          ((codepoint >> 12) & 0b1111) | 0b11100000,
          ((codepoint >> 6) & 0b111111) | 0b10000000,
          (codepoint & 0b111111) | 0b10000000
        ]
      end

      # Connect the states for values that fall within the range that would be
      # encoded with three bytes.
      def connect_bytes3(range)
        # We can shortcut if the range entirely encapsulates the potential range
        # of codepoints that can be encoded with three bytes.
        if range_encapsulates?(range, BYTES3_RANGE)
          min_bytes = encode_bytes3(BYTES3_RANGE.begin)
          max_bytes = encode_bytes3(BYTES3_RANGE.end)

          byte1 = connector.state
          byte2 = connector.state

          connector.connect_range(connector.from, byte1, min_bytes[0]..max_bytes[0])
          connector.connect_range(byte1, byte2, min_bytes[1]..max_bytes[1])
          connector.connect_range(byte2, connector.to, min_bytes[2]..max_bytes[2])
          return
        end

        byte1_step = 1 << 12
        byte2_step = 1 << 6

        BYTES3_RANGE.begin.step(BYTES3_RANGE.end, byte1_step) do |parent_step_min|
          parent_step_max = parent_step_min + byte1_step - 1

          if ranges_overlap?(range, parent_step_min..parent_step_max)
            parent_step_min.step(parent_step_max, byte2_step) do |child_step_min|
              child_step_max = child_step_min + byte2_step - 1

              if ranges_overlap?(range, child_step_min..child_step_max)
                min_bytes = encode_bytes3([child_step_min, range.begin].max)
                max_bytes = encode_bytes3([child_step_max, range.end].min)
                assert_equal_leading_bytes(min_bytes, max_bytes)

                byte1 = connector.state
                byte2 = connector.state

                connector.connect_range(connector.from, byte1, min_bytes[0]..max_bytes[0])
                connector.connect_range(byte1, byte2, min_bytes[1]..max_bytes[1])
                connector.connect_range(byte2, connector.to, min_bytes[2]..max_bytes[2])
              end
            end
          end
        end
      end

      # 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
      def encode_bytes4(codepoint)
        [
          ((codepoint >> 18) & 0b111) | 0b11110000,
          ((codepoint >> 12) & 0b111111) | 0b10000000,
          ((codepoint >> 6) & 0b111111) | 0b10000000,
          (codepoint & 0b111111) | 0b10000000
        ]
      end

      # Connect the states for values that fall within the range that would be
      # encoded with four bytes.
      def connect_bytes4(range)
        # We can shortcut if the range entirely encapsulates the potential range
        # of codepoints that can be encoded with four bytes.
        if range_encapsulates?(range, BYTES4_RANGE)
          min_bytes = encode_bytes4(BYTES4_RANGE.begin)
          max_bytes = encode_bytes4(BYTES4_RANGE.end)

          byte1 = connector.state
          byte2 = connector.state
          byte3 = connector.state

          connector.connect_range(connector.from, byte1, min_bytes[0]..max_bytes[0])
          connector.connect_range(byte1, byte2, min_bytes[1]..max_bytes[1])
          connector.connect_range(byte2, byte3, min_bytes[2]..max_bytes[2])
          connector.connect_range(byte3, connector.to, min_bytes[3]..max_bytes[3])
          return
        end

        byte1_step = 1 << 18
        byte2_step = 1 << 12
        byte3_step = 1 << 6

        BYTES4_RANGE.begin.step(BYTES4_RANGE.end, byte1_step) do |grand_parent_step_min|
          grand_parent_step_max = grand_parent_step_min + byte1_step - 1

          if ranges_overlap?(range, grand_parent_step_min..grand_parent_step_max)
            grand_parent_step_min.step(grand_parent_step_max, byte2_step) do |parent_step_min|
              parent_step_max = parent_step_min + byte2_step - 1

              if ranges_overlap?(range, parent_step_min..parent_step_max)
                parent_step_min.step(parent_step_max, byte3_step) do |child_step_min|
                  child_step_max = child_step_min + byte3_step - 1

                  if ranges_overlap?(range, child_step_min..child_step_max)
                    min_bytes = encode_bytes4([child_step_min, range.begin].max)
                    max_bytes = encode_bytes4([child_step_max, range.end].min)
                    assert_equal_leading_bytes(min_bytes, max_bytes)

                    byte1 = connector.state
                    byte2 = connector.state
                    byte3 = connector.state

                    connector.connect_range(connector.from, byte1, min_bytes[0]..max_bytes[0])
                    connector.connect_range(byte1, byte2, min_bytes[1]..max_bytes[1])
                    connector.connect_range(byte2, byte3, min_bytes[2]..max_bytes[2])
                    connector.connect_range(byte3, connector.to, min_bytes[3]..max_bytes[3])
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
