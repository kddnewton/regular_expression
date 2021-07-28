# frozen_string_literal: true

require "stringio"

# ruby/spec runs everything with mspec, but I don't feel like cloning down a
# whole other submodule just to get these things running. So I'm copying down
# just the subset that we're actually using.
module MSpec
  module SuiteDSL
    def describe(_name, &block)
      Class.new(Minitest::Test, &block)
    end
  end

  module TestDSL
    def it(name, &block)
      define_method("test_ #{name}", &block)
    end
  end

  module Matchers
    class BeNil
      def match(value)
        raise "Expected #{value.inspect} to be nil" unless value.nil?
      end
    end

    # object.should be_nil
    def be_nil
      BeNil.new
    end

    class RaiseError < Struct.new(:error)
      def match(value)
        value.call
        raise "Expected #{value.inspect} to raise #{value.inspect}"
      rescue error
        # expected error was raised
      end
    end

    # object.should raise_error(StandardError)
    def raise_error(error)
      RaiseError.new(error)
    end

    class Complain < Struct.new(:pattern)
      def match(value)
        stderr = $stderr
        verbose = $VERBOSE

        captured = StringIO.new
        $stderr = captured
        $VERBOSE = false

        begin
          value.call
        ensure
          $stderr = stderr
          $VERBOSE = verbose
        end

        warning = captured.string
        return if pattern.match?(warning)

        raise "Expected #{warning.inspect} to match #{pattern.inspect}"
      end
    end

    # object.should complain(/my warning/)
    def complain(pattern)
      Complain.new(pattern)
    end

    class Include < Struct.new(:needle)
      def match(value)
        return if value.include?(needle)

        raise "Expected #{value.inspect} to include #{needle.inspect}"
      end
    end

    # object.should include("needle")
    def include(needle)
      Include.new(needle)
    end

    # object.should == something
    class Object < Struct.new(:value)
      def ==(other)
        return if value == other

        raise "Expected #{value.inspect} to == #{other.inspect}"
      end
    end
  end

  module Helpers
    def suppress_warning
      verbose = $VERBOSE
      $VERBOSE = nil
      yield
    ensure
      $VERBOSE = verbose
    end
  end

  # These are the methods that actually trigger matchers
  module Expectations
    def should(matcher = nil)
      matcher ? matcher.match(self) : Matchers::Object.new(self)
    end
  end

  module Guards
    # Ignore the not_supported_on as we're just going to run everything
    def not_supported_on(_platform, &_block)
      yield
    end

    # If it's linked to a specific bug for a range of Ruby versions, just ignore
    def ruby_bug(description, range, &block); end
  end
end

Object.include(MSpec::SuiteDSL)
Object.include(MSpec::Expectations)
Object.include(MSpec::Guards)

Minitest::Test.extend(MSpec::TestDSL)
Minitest::Test.include(MSpec::Matchers)
Minitest::Test.include(MSpec::Helpers)
