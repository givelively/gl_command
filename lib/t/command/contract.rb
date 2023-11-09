# frozen_string_literal: true

module T
  module Contract
    def self.included(base)
      base.class_eval do
        include ActiveModel::Validations
        extend ClassMethods

        before :validate_contract!
        after :validate_return_contract!
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
        if attributes.present?
          validates(*attributes, presence: true)
          delegate(*attributes, to: :context)
        end
        return if strong_attributes.blank?

        strong_attributes.each_key { |strng_attr| delegate(strng_attr, to: :context) }
        validates_each strong_attributes.keys do |record, attr_name, value|
          type = strong_attributes[attr_name].name.downcase.to_sym
          record.errors.add attr_name, "does not act like #{type}" unless value.acts_like?(type)
        end
      end

      def returns(*attributes, **strong_attributes)
        delegate(*attributes, to: :context)
        strong_attributes.each_key { |strng_attr| delegate(strng_attr, to: :context) }
        @return_attributes = attributes
        @return_strong_attributes = strong_attributes
      end
    end

    def validate_contract!
      return if valid?

      context.errors.copy!(errors)
      raise ContractFailure
    end

    def validate_return_contract!
      validate_return_attributes!
      validate_strong_return_attributes!
    end

    def strong_attributes
      self.class.instance_variable_get(:@return_strong_attributes) || []
    end

    def validate_return_attributes!
      attributes = self.class.instance_variable_get(:@return_attributes)
      return if attributes.blank?

      attributes.each do |attribute|
        next if context[attribute].present?

        record.errors.add attribute, 'is not being returned'
        context.errors.copy!(errors)
        raise ContractFailure
      end
    end

    def validate_strong_return_attributes!
      strong_attributes.each do |attribute, type|
        if context[attribute].blank?
          context.errors.add strong_attribute, 'is not being returned'
          raise ContractFailure
        end
        type = type.name.downcase.to_sym
        next if context[attribute].acts_like?(type)

        context.errors.add attribute, "is returned, but does not act like a #{type}"
        raise ContractFailure
      end
    end
  end
end
