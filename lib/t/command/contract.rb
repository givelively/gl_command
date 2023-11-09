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
        delegate(*attributes, to: :context) if attributes.present?
        return if strong_attributes.blank?

        strong_attributes.each_key { |strng_attr| delegate(strng_attr, to: :context) }
        validates_each strong_attributes.keys do |record, attr_name, value|
          next if value.blank?

          type = strong_attributes[attr_name].name.downcase.to_sym
          record.errors.add attr_name, "does not act like #{type}" unless value.acts_like?(type)
        end
      end

      def requires(*attributes, **strong_attributes)
        validate_and_delegate_attributes(attributes) if attributes.present?

        return if strong_attributes.blank?
        strong_attributes.each_key { |strng_attr| delegate(strng_attr, to: :context) }
        validates_each strong_attributes.keys do |record, attr_name, value|
          type = strong_attributes[attr_name].name.downcase.to_sym
          record.errors.add attr_name, "does not act like #{type}" unless value.acts_like?(type)
        end
      end

      def returns(*attributes)
        delegate(*attributes, to: :context)
      end

      private

      def validate_and_delegate_attributes(attributes)
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
