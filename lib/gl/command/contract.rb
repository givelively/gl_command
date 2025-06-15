# frozen_string_literal: true

module GL
  module Contract
    def self.included(base)
      base.class_eval do
        include ActiveModel::Validations
        extend ClassMethods

        before :apply_defaults!
        before :validate_contract!
        after :validate_return_contract!
      end
    end

    module ClassMethods
      def self.extended(base)
        base.instance_variable_set(:@defaults, {})
      end

      def inherited(subclass)
        super
        defaults = instance_variable_get(:@defaults)
        subclass.instance_variable_set(:@defaults, defaults.dup)
      end

      def allows(*attributes, **strong_attributes)
        delegate(*attributes, to: :context)
        return if strong_attributes.blank?

        typed_attributes = parse_strong_attributes(**strong_attributes)
        delegate(*typed_attributes.keys, to: :context)
        enforce_attribute_types(**typed_attributes)
      end

      def requires(*attributes, **strong_attributes)
        requires_attributes(*attributes)
        requires_strong_attributes(**strong_attributes)
      end

      def requires_attributes(*attributes)
        return if attributes.blank?

        delegate(*attributes, to: :context)
        enforce_attribute_presence(*attributes)
      end

      def requires_strong_attributes(**attributes)
        return if attributes.blank?

        typed_attributes = parse_strong_attributes(**attributes)
        requires_attributes(*typed_attributes.keys)
        enforce_attribute_types(**typed_attributes)
      end

      def returns(*attributes, **strong_attributes)
        delegate(*attributes, to: :context)
        @return_attributes = attributes
        return if strong_attributes.blank?

        strong_attribute_keys = strong_attributes.keys
        delegate(*strong_attribute_keys, to: :context)
        @return_attributes.concat(strong_attribute_keys)
        @return_strong_attributes = strong_attributes
      end

      def enforce_attribute_presence(*attributes)
        validates(*attributes, presence: true) if attributes.present?
      end

      def enforce_attribute_types(**attributes)
        return if attributes.blank?

        validates_each attributes.keys do |record, attr_name, value|
          next if value.blank?

          type = attributes[attr_name]
          record.errors.add attr_name, "does is not a #{type}" unless type_applies?(value, type)
        end
      end

      private

      def parse_strong_attributes(**attributes)
        simple_attributes = attributes.select { |_, v| !v.is_a?(Hash) }
        complex_attributes = attributes.select { |_, v| v.is_a?(Hash) }

        complex_attributes.each do |attr, opts|
          @defaults[attr] = opts[:default] if opts.key?(:default)
        end

        simple_attributes.merge(
          complex_attributes.transform_values { |v| v[:type] }.compact
        )
      end

      def type_applies?(value, type)
        value.is_a?(type) || value.acts_like?(type.name.downcase.to_sym)
      end
    end

    def apply_defaults!
      klass.instance_variable_get(:@defaults).each do |attr, default|
        next if context.to_h.key?(attr)

        value = default.is_a?(Proc) ? instance_exec(&default) : default
        context[attr] = value
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
