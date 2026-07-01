# frozen_string_literal: true

require 'active_support/concern'
require 'active_model'
require 'active_record'

module GLCommand
  module Validatable
    extend ActiveSupport::Concern
    # In reality, validations should be in the context
    # BUT, since we don't write context classes,
    # we need to have everything about validations get passed
    include ActiveModel::Validations

    class_methods do
      define_method(:i18n_scope) do
        :activerecord
      end
    end

    # This is called in Callable.perform_call (via validate_validatable!)
    def validatable_valid?
      context.assign_callable(self) # used by validatable
      validate
      errors.none?
    end

    def validate_validatable!
      return true if validatable_valid?

      stop_and_fail!(ActiveRecord::RecordInvalid.new(self), no_notify: true)
    end
  end
end
