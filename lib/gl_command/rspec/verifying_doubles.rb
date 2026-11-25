# frozen_string_literal: true

module GLCommand
  module RSpec
    module VerifyingDoubleSupport
      private

      def value_matches_type?(value, type)
        if !type.is_a?(Symbol) && instance_verifying_double?(value) &&
           verifying_double_matches_type?(value, type)
          return true
        end

        super
      end

      def instance_verifying_double?(value)
        defined?(::RSpec::Mocks::InstanceVerifyingDouble) &&
          value.is_a?(::RSpec::Mocks::InstanceVerifyingDouble)
      end

      def verifying_double_matches_type?(value, type)
        return false unless type.is_a?(Module)

        doubled_target = value.instance_variable_get(:@doubled_module)&.target
        doubled_target.is_a?(Module) && (doubled_target <= type || false)
      end
    end
  end
end

unless GLCommand::Callable <= GLCommand::RSpec::VerifyingDoubleSupport
  GLCommand::Callable.prepend(GLCommand::RSpec::VerifyingDoubleSupport)
end
