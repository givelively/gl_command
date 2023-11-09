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
      def allows(*attributes, **strong_attributes)
        delegate(*attributes, to: :context)
        strong_attributes.each_key { |strong_attribute| delegate(strong_attribute, to: :context) }

        validates_each strong_attributes.keys do |record, attr_name, value|
          next if value.blank?

          type = strong_attributes[attr_name].name.downcase.to_sym
          record.errors.add attr_name, "is not of type #{type}" unless value.acts_like?(type)
        end
      end

      def requires(*attributes)
        validate_attributes(attributes)
      end

      def returns(*attributes)
        delegate(*attributes, to: :context)
      end

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
