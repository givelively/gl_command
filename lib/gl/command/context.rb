# frozen_string_literal: true

module GL
  class Context
    attr_accessor :error
    attr_reader :class_attrs

    def initialize(klass, raise_errors: false)
      @klass = klass
      @error = nil
      @raise_errors = raise_errors.nil? ? false : raise_errors
      @class_attrs = klass.returns + klass.arguments
      @class_attrs.each do |arg|
        # It would be nice to have per-command context classes, and define attr_accessor on the class,
        # (rather than on each instance)
        singleton_class.class_eval { attr_accessor arg }
      end
    end

    def raise_errors?
      @raise_errors
    end

    def fail!(passed_error = nil)
      @failure = true
      self.error = passed_error if passed_error
      self
    end

    def failure?
      @failure || false
    end

    def success?
      !failure?
    end

    alias_method :successful?, :success?

    def to_h
      class_attrs.index_with { |cattr| send(cattr) }
    end

    def inspect
      "<GL::Context '#{@klass}' success: #{success?}, error: #{error}, data: #{to_h}>"
    end
  end
end
