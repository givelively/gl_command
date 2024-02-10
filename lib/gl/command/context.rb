# frozen_string_literal: true

module GL
  class Context
    attr_accessor :error

    def initialize(klass, do_not_raise: false)
      @klass = klass
      @error = nil
      @do_not_raise = !!do_not_raise
      @returns = klass.returns
      @returns.each do |arg|
        # It would be nice to have per-command context classes, and define attr_accessor on the class,
        # (rather than on each instance)
        singleton_class.class_eval { attr_accessor arg }
      end
    end

    def raise_error?
      !@do_not_raise
    end

    def fail!(passed_error = nil)
      @failure = true
      self.error = passed_error if passed_error
      self # Return self
    end

    def failure?
      @failure || false
    end

    def success?
      !failure?
    end

    alias_method :successful?, :success?

    def inspect
      "<GL::Context '#{@klass}' success: #{success?}, error: #{error}, returns: #{@returns}>"
    end
  end
end
