# frozen_string_literal: true

require 'active_support/concern'

module GLCommand
  module ArgumentTypeValidation
    extend ActiveSupport::Concern

    class_methods do
      private

      def validate_context_argument_types!(**arguments_and_returns)
        validator = allocate
        requires.merge(allows).each do |arg, type|
          next unless arguments_and_returns.key?(arg)

          validator.send(:validate_argument_type!, arg, arguments_and_returns[arg], type)
        end
      end

      def test_environment?
        return Rails.env.test? if defined?(Rails) && Rails.respond_to?(:env) && Rails.env

        defined?(RSpec) || ENV['RAILS_ENV'] == 'test' || ENV['RACK_ENV'] == 'test'
      end
    end

    private

    def validate_argument_type!(arg, value, type)
      return if type.nil? || Array(type).any? { |t| value_matches_type?(value, t) }
      # Validation skipped if allows and nil (but not if blank)
      return if value.nil? && self.class.allows.include?(arg)

      raise GLCommand::ArgumentTypeError, ":#{arg} is not #{type_error_str(type)}"
    end

    # A type can be a class (checked with is_a?) or a symbol naming a predicate
    # method the value must respond to and return truthy from.
    # In RSpec test environments, an InstanceVerifyingDouble matches a Class/Module
    # type when its doubled module/class is `<= type`.
    def value_matches_type?(value, type)
      return value.respond_to?(type) && value.public_send(type) if type.is_a?(Symbol)
      return verifying_double_matches_type?(value, type) if instance_verifying_double?(value)

      value.is_a?(type)
    end

    def instance_verifying_double?(value)
      defined?(RSpec::Mocks::InstanceVerifyingDouble) &&
        value.is_a?(RSpec::Mocks::InstanceVerifyingDouble)
    end

    def verifying_double_matches_type?(value, type)
      return false unless type.is_a?(Module)

      doubled_target = value.instance_variable_get(:@doubled_module)&.target
      doubled_target.is_a?(Module) && (doubled_target <= type || false)
    end

    def type_error_str(type)
      return "one of #{type.join(', ')}" if type.is_a?(Array)

      type.is_a?(Symbol) ? type.to_s : "a #{type}"
    end
  end
end
