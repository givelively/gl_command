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
        delegate_attributes(*attributes)
        return if strong_attributes.blank?

        delegate_attributes(*strong_attributes.keys)
        enforce_attribute_types(**strong_attributes)
      end

      def requires(*attributes, **strong_attributes)
        requires_attributes(*attributes)
        requires_strong_attributes(**strong_attributes)
      end

      def requires_attributes(*attributes)
        return if attributes.blank?

        delegate_attributes(*attributes)
        enforce_attribute_presence(*attributes)
      end

      def requires_strong_attributes(**attributes)
        return if attributes.blank?

        attribute_keys = attributes.keys
        requires_attributes(*attribute_keys)
        enforce_attribute_types(**attributes)
      end

      def returns(*attributes, **strong_attributes)
        delegate_attributes(*attributes)
        @return_attributes = attributes
        return if strong_attributes.blank?

        strong_attribute_keys = strong_attributes.keys
        delegate_attributes(*strong_attribute_keys)
        @return_attributes.concat(strong_attribute_keys)
        @return_strong_attributes = strong_attributes
      end

      def delegate_attributes(*attributes)
        delegate(*attributes, to: :context)
      end

      def enforce_attribute_presence(*attributes)
        validates(*attributes, presence: true) if attributes.present?
      end

      def enforce_attribute_types(**attributes)
        return if attributes.blank?

        validates_each attributes.keys do |record, attr_name, value|
          next if value.blank?

          type = attributes[attr_name].name.downcase.to_sym
          record.errors.add attr_name, "does not act like #{type}" unless value.acts_like?(type)
        end
      end
    end

    def validate_contract!
      return if valid?

      context.errors.copy!(errors)
      raise ContractFailure
    end

    def validate_return_contract!
      klass.enforce_attribute_presence(*return_attributes)
      klass.enforce_attribute_types(**return_strong_attributes)
      return if valid?

      context.errors.copy!(errors)
      raise ContractFailure
    end

    def return_attributes
      klass.instance_variable_get(:@return_attributes) || []
    end

    def return_strong_attributes
      klass.instance_variable_get(:@return_strong_attributes) || {}
    end

    def klass
      self.class
    end
  end
end
