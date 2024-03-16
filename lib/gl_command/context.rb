# frozen_string_literal: true

module GlCommand
  class Context
    attr_accessor :error
    attr_reader :klass, :arguments

    delegate :chain?, to: :klass

    def initialize(klass, raise_errors: false)
      @klass = klass
      @raise_errors = raise_errors.nil? ? false : raise_errors
      if chain?
        @called = []
        singleton_class.class_eval { attr_accessor :called }
        assign_arguments_and_returns(@klass.chain_arguments, @klass.chain_returns)
      else
        assign_arguments_and_returns(@klass.arguments, @klass.returns)
      end
    end

    def returns
      klass.returns.map { |rattr| [rattr, send(rattr)] }.to_h
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

    def to_s
      inspect
    end

    def inspect
      "<GlCommand::Context '#{klass}' #{inspect_values}>"
    end

    private

    def inspect_values
      [
        "success: #{success?}",
        "error: #{error || 'nil'}",
        "arguments: #{arguments}",
        "returns: #{returns}",
        chain? ? "called: #{called}" : nil,
      ].compact.join(', ')
    end

    def assign_arguments_and_returns(klass_arguments, klass_returns)
      klass_returns.each do |arg|
        # It would be nice to have per-command context classes, and define attr_accessor on the class,
        # (rather than on each instance)
        singleton_class.class_eval { attr_accessor arg }
      end
      @arguments = Hash[klass_arguments.zip]
    end
  end
end
