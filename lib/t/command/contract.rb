# frozen_string_literal: true

module T
  module Contract
    def self.included(base)
      base.class_eval do
        include ActiveModel::Validations
        extend ClassMethods

        before :validate_contract!
      end
    end

    module ClassMethods
      def allows; end

      def requires(*attributes)
        validate_attributes(attributes)
      end

      def returns; end

      private

      def validate_attributes(attributes)
        validates(*attributes, presence: true)
        delegate(*attributes, to: :context)
      end
    end

    def validate_contract!
      return if valid?

      context.errors.copy!(errors)
      raise ContractFailure
    end
  end
end
