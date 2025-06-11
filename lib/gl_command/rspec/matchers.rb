# frozen_string_literal: true

# This file is intended to be required by lib/gl_command/rspec.rb

module GLCommand
  module Matchers
    # Base matcher for `requires` and `allows`, which store a Hash of { attribute: Type }.
    class CommandArgumentMatcher
      def initialize(attribute)
        @attribute = attribute
        @expected_type = nil
      end

      def being(expected_type)
        @expected_type = expected_type
        self
      end

      def matches?(command_class)
        @command_class = command_class.is_a?(Class) ? command_class : command_class.class
        attributes = @command_class.public_send(scope)

        return false unless attributes.key?(@attribute)
        return true if @expected_type.nil? # Type check not requested

        attributes[@attribute] == @expected_type
      end

      def description
        "#{action} argument `#{@attribute}`"
      end

      def failure_message
        message = "Expected #{@command_class.name} to #{action} `#{@attribute}`"
        message += " of type `#{@expected_type}`" if @expected_type
        message
      end

      def failure_message_when_negated
        message = "Expected #{@command_class.name} not to #{action} `#{@attribute}`"
        message += " of type `#{@expected_type}`" if @expected_type
        message
      end
    end

    class RequireArgumentMatcher < CommandArgumentMatcher
      private

      def scope; :requires; end
      def action; 'require'; end
    end

    class AllowArgumentMatcher < CommandArgumentMatcher
      private

      def scope; :allows; end
      def action; 'allow'; end
    end

    # Specific matcher for `returns`, which only stores an Array of keys.
    class ReturnAttributeMatcher
      def initialize(attribute)
        @attribute = attribute
        @type_check_attempted = false
      end

      def being(_expected_type)
        @type_check_attempted = true
        self
      end

      def matches?(command_class)
        @command_class = command_class.is_a?(Class) ? command_class : command_class.class

        if @type_check_attempted
          @failure_reason = 'GLCommand::Callable does not store types for `returns`, so `.being()` cannot be used.'
          return false
        end

        @command_class.returns.include?(@attribute)
      end

      def description
        "return attribute `#{@attribute}`"
      end

      def failure_message
        return @failure_reason if @failure_reason

        "Expected #{@command_class.name} to return `#{@attribute}`"
      end

      def failure_message_when_negated
        "Expected #{@command_class.name} not to return `#{@attribute}`"
      end
    end

    # Helper methods to provide the clean syntax in specs
    def require(attribute)
      RequireArgumentMatcher.new(attribute)
    end

    def allow(attribute)
      AllowArgumentMatcher.new(attribute)
    end

    def return(attribute)
      ReturnAttributeMatcher.new(attribute)
    end
  end
end
