# frozen_string_literal: true

module RegularExpression
  module Compiler
    module X86
      class Compiled
        RETURN_FAILED = 0xffffffffffffffff
        RETURN_DEOPT = RETURN_FAILED - 1

        attr_reader :buffer

        def initialize(buffer)
          @buffer = buffer
        end

        def disasm
          output = StringIO.new

          crabstone = Crabstone::Disassembler.new(Crabstone::ARCH_X86, Crabstone::MODE_64)
          crabstone.disasm(buffer.memory.to_s(buffer.pos), buffer.memory.to_i).each do |insn|
            output.printf(
              "0x%<address>x:\t%<instruction>s\t%<details>s\n",
              address: insn.address,
              instruction: insn.mnemonic,
              details: insn.op_str
            )
          end

          output.string
        end

        def to_proc
          function = buffer.to_function([Fiddle::TYPE_VOIDP, Fiddle::TYPE_SIZE_T], Fiddle::TYPE_SIZE_T)

          lambda do |string|
            value = function.call(string, string.length)
            case value
            when RETURN_FAILED
              nil
            when RETURN_DEOPT
              raise Pattern::Deoptimize
            else
              value
            end
          end
        end
      end

      # Generate native code for a CFG. This looks just like the Ruby generator
      # but abstracted one level, or just like the interpreter but abstracted
      # two levels!
      def self.compile(cfg, schedule)
        fisk = Fisk.new
        stringio = StringIO.new("".b)

        fisk.asm(stringio) do
          # Here we're setting up a couple of local variables that point to
          # registers so that it's easier to see what's actually going on

          # rax is a scratch register that is used for the return value of the
          # function
          return_value = rax

          # rcx is a scratch register that is used to track the index of the
          # string where we're currently looking
          string_index = rcx

          # rdx is a scratch register that is used to track the index of the
          # string where we've started the match
          match_index = rdx

          # rsp is a reserved register that stores a pointer to the stack
          stack_pointer = rsp

          # rbp is a reserved register that stores a pointer to the base of the
          # stack. It is also known as the frame pointer
          frame_pointer = rbp

          # rsi is a scratch register that stores the second argument to the
          # function, and in our case stores the length of the string
          string_length = rsi

          # rdi is a scratch register that stores the first argument to the
          # function, and in our case stores a pointer to the base of the string
          string_pointer = rdi

          # r8 is a scratch register that we're using to store the last read
          # character value from the string
          character_buffer = r8

          # r9 is a scratch register that we're using to store the flag that is
          # the last comparison to the current character buffer - this could
          # likely take advantage of ZF or some other flag but that's for a
          # future optimization
          flag = r9

          # r10 is a scratch register that we're using for a couple of things:
          #
          # - store a pointer to a comparison function (e.g., isalnum) for a
          #   POSIX character type
          # - store the size of a lookahead assertion so that we can do the
          #   subtraction
          scratch = r10

          # First we're going to do some initialization of the frame pointer and
          # stack pointer so we can clear the stack when we're done with this
          # function
          push frame_pointer
          mov frame_pointer, stack_pointer

          # Now we're going to initialize the counter to 0 so that we attempt to
          # match at each index of the input string
          xor match_index, match_index

          # This is the start of our loop, where at the beginning of the loop
          # we check if we have already finished looking at each index (in which
          # case we'll jump to a failure condition)
          make_label :start_loop_head
          cmp match_index, string_length
          jg label(:exit)

          # Set the string_index value to the match_index value so that we begin
          # each loop at the current match index
          mov string_index, match_index

          schedule.each_with_index do |block, n|
            next_block = schedule[n + 1]

            # Label the start of each block so that we can jump between them
            make_label block.name

            block.insns.each do |insn|
              case insn
              when Bytecode::Insns::PushIndex
                push string_index
              when Bytecode::Insns::PopIndex
                pop string_index
              when Bytecode::Insns::TestBegin
                over_label = :"over_#{insn.object_id}"
                end_label = :"end_#{insn.object_id}"
                cmp string_index, imm8(0)
                je label(over_label)
                mov flag, imm32(0)
                jmp label(end_label)
                make_label over_label
                mov flag, imm32(1)
                make_label end_label
              when Bytecode::Insns::TestEnd
                over_label = :"over_#{insn.object_id}"
                end_label = :"end_#{insn.object_id}"
                cmp string_index, string_length
                je label(over_label)
                mov flag, imm32(0)
                jmp label(end_label)
                make_label over_label
                mov flag, imm32(1)
                make_label end_label
              when Bytecode::Insns::StartCapture
                # raise NotImplementedError
              when Bytecode::Insns::EndCapture
                # raise NotImplementedError
              when Bytecode::Insns::TestAny
                no_match_label = :"no_match_#{insn.object_id}"
                end_label = :"end_#{insn.object_id}"

                # Ensure we have a character we can read
                cmp string_index, string_length
                je label(no_match_label)

                # Move the string index forward and jump to the target
                # instruction
                inc string_index
                mov flag, imm32(1)
                jmp label(end_label)

                make_label no_match_label
                mov flag, imm32(0)

                make_label end_label
              when Bytecode::Insns::TestValue
                no_match_label = :"no_match_#{insn.object_id}"
                end_label = :"end_#{insn.object_id}"

                # Ensure we have a character we can read
                cmp string_index, string_length
                je label(no_match_label)

                # Read the character into the character buffer
                mov character_buffer, string_pointer
                add character_buffer, string_index
                mov character_buffer, m64(character_buffer)

                # Compare the character buffer to the instruction's character,
                # continue on to the next instruction if it's not equal
                cmp character_buffer, imm8(insn.char.ord)
                jne label(no_match_label)

                # Move the string index forward and jump to the target
                # instruction
                inc string_index
                mov flag, imm32(1)
                jmp label(end_label)

                make_label no_match_label
                mov flag, imm32(0)

                make_label end_label
              when Bytecode::Insns::TestType
                no_match_label = :"no_match_#{insn.object_id}"
                end_label = :"end_#{insn.object_id}"

                # Ensure we have a character we can read
                cmp string_index, string_length
                je label(no_match_label)

                # Read the character into the character buffer
                mov character_buffer, string_pointer
                add character_buffer, string_index
                mov character_buffer, m64(character_buffer)

                # Call out to the character type checker function. We have to
                # push/pop rdi since that's the first argument register to the
                # function
                push rdi
                mov rdi, character_buffer
                mov scratch, imm64(insn.type.handle)
                call scratch
                pop rdi

                # Compare the return value of the function call to zero to check
                # if the value is within the character type
                test return_value, return_value
                jz label(no_match_label)

                # Move the string index forward and jump to the target
                # instruction
                inc string_index
                mov flag, imm32(1)
                jmp label(end_label)

                make_label no_match_label
                mov flag, imm32(0)

                make_label end_label
              when Bytecode::Insns::TestValuesInvert
                no_match_label = :"no_match_#{insn.object_id}"
                end_label = :"end_#{insn.object_id}"

                # Ensure we have a character we can read
                cmp string_index, string_length
                je label(no_match_label)

                # Read the character into the character buffer
                mov character_buffer, string_pointer
                add character_buffer, string_index
                mov character_buffer, m64(character_buffer)

                # Compare the character buffer to each of the instruction's
                # characters, continue on to the next instruction if any of them
                # are equal
                insn.chars.each do |value|
                  cmp character_buffer, imm8(value.ord)
                  je label(no_match_label)
                end

                # Move the string index forward and jump to the target
                # instruction
                inc string_index
                mov flag, imm32(1)
                jmp label(end_label)

                make_label no_match_label
                mov flag, imm32(0)

                make_label end_label
              when Bytecode::Insns::TestRange
                no_match_label = :"no_match_#{insn.object_id}"
                end_label = :"end_#{insn.object_id}"

                # Ensure we have a character we can read
                cmp string_index, string_length
                je label(no_match_label)

                # Read the character into the character buffer
                mov character_buffer, string_pointer
                add character_buffer, string_index
                mov character_buffer, m64(character_buffer)

                # Compare the character buffer to the left hand side of the
                # instruction's range, continue on to the next instruction if
                # it's outside the range
                cmp character_buffer, imm8(insn.left.ord)
                jl label(no_match_label)

                # Compare the character buffer to the right hand side of the
                # instruction's range, continue on to the next instruction if
                # it's outside the range
                cmp character_buffer, imm8(insn.right.ord)
                jg label(no_match_label)

                # Move the string index forward and jump to the target
                # instruction
                inc string_index
                mov flag, imm32(1)
                jmp label(end_label)

                make_label no_match_label
                mov flag, imm32(0)

                make_label end_label
              when Bytecode::Insns::TestRangeInvert
                no_match_label = :"no_match_#{insn.object_id}"
                match_label = :"match_#{insn.object_id}"
                end_label = :"end_#{insn.object_id}"

                # Ensure we have a character we can read
                cmp string_index, string_length
                je label(no_match_label)

                # Read the character into the character buffer
                mov character_buffer, string_pointer
                add character_buffer, string_index
                mov character_buffer, m64(character_buffer)

                # Compare the character buffer to the left hand side of the
                # instruction's range, jump down to the success case if it's
                # outside the range
                cmp character_buffer, imm8(insn.left.ord)
                jl label(match_label)

                # Compare the character buffer to the right hand side of the
                # instruction's range, continue on to the next instruction if
                # it's inside the range
                cmp character_buffer, imm8(insn.right.ord)
                jle label(no_match_label)

                # Move the string index forward and jump to the target
                # instruction
                make_label match_label
                inc string_index
                mov flag, imm32(1)
                jmp label(end_label)

                make_label no_match_label
                mov flag, imm32(0)

                make_label end_label
              when Bytecode::Insns::TestPositiveLookahead
                no_match_label = :"no_match_#{insn.object_id}"
                end_label = :"end_#{insn.object_id}"

                # Ensure we have enough characters to assert against
                mov scratch, string_length
                sub scratch, string_index
                cmp scratch, imm8(insn.value.length)
                jl label(no_match_label)

                # Check each character against the input string, jump to the
                # failure case if any of them don't match
                insn.value.each_char.with_index do |char, index|
                  # Move the correct character into the buffer
                  mov character_buffer, string_pointer
                  add character_buffer, string_index
                  add character_buffer, imm8(index) if index != 0
                  mov character_buffer, m64(character_buffer)

                  # Compare against the character
                  cmp character_buffer, imm8(char.ord)
                  jne label(no_match_label)
                end

                # Set the flag to be true since we're in the success case
                mov flag, imm32(1)
                jmp label(end_label)

                # Set up the non-matching label to set the flag to 0
                make_label no_match_label
                mov flag, imm32(0)

                make_label end_label
              when Bytecode::Insns::TestNegativeLookahead
                match_label = :"match_#{insn.object_id}"

                # Assume we're going to be successful
                mov flag, imm32(1)

                # Ensure we have enough characters to assert against. If we
                # don't, then we're successful.
                mov scratch, string_length
                sub scratch, string_index
                cmp scratch, imm8(insn.value.length)
                jl label(match_label)

                # Check each character against the input string, jump to the
                # failure case if any of them don't match
                insn.value.each_char.with_index do |char, index|
                  # Move the correct character into the buffer
                  mov character_buffer, string_pointer
                  add character_buffer, string_index
                  add character_buffer, imm8(index) if index != 0
                  mov character_buffer, m64(character_buffer)

                  # Compare against the character
                  cmp character_buffer, imm8(char.ord)
                  jne label(match_label)
                end

                # Set the flag to false since we're in the failure case
                mov flag, imm32(0)

                make_label match_label
              when Bytecode::Insns::Branch
                true_block = cfg.label_map[insn.true_target]
                false_block = cfg.label_map[insn.false_target]

                if next_block == true_block
                  # Falls through to the true blocks - jump for false.
                  cmp flag, imm32(0)
                  je label(false_block.name)
                elsif next_block == false_block
                  # Falls through for the false block - jump for true.
                  cmp flag, imm32(1)
                  je label(true_block.name)
                else
                  # Doesn't fall through to either block - have to jump for
                  # both.
                  cmp flag, imm32(1)
                  je label(true_block.name)
                  jmp label(false_block.name)
                end
              when Bytecode::Insns::Jump
                target_block = cfg.label_map[insn.target]

                # Fall through if the next branch is not the target block
                jmp label(target_block.name) if next_block != target_block
              when Bytecode::Insns::Match
                # If we reach this instruction, then we've successfully matched
                # against the input string, so we're going to return the integer
                # that represents the index at which this match began
                mov return_value, match_index
                mov stack_pointer, frame_pointer
                pop frame_pointer
                ret
              when Bytecode::Insns::Fail
                inc match_index
                jmp label(:start_loop_head)
              when Bytecode::Insns::Deoptimize
                mov return_value, imm64(RegularExpression::Compiler::X86::Compiled::RETURN_DEOPT)
                mov stack_pointer, frame_pointer
                pop frame_pointer
                ret
              else
                raise
              end
            end
          end

          # If we reach this instruction, then we've failed to match at every
          # possible index in the string, so we're going to return the length
          # of the string + 1 so that the caller knows that this match failed
          make_label :exit
          mov return_value, imm64(RegularExpression::Compiler::X86::Compiled::RETURN_FAILED)

          # Here we make sure to clean up after ourselves by returning the frame
          # pointer to its former position
          mov stack_pointer, frame_pointer
          pop frame_pointer

          ret
        end

        buffer = Fisk::Helpers.jitbuffer(stringio.size)
        stringio.rewind
        stringio.each_byte(&buffer.method(:putc))

        Compiled.new(buffer)
      end
    end
  end
end
