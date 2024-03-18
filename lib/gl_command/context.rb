# frozen_string_literal: true

module GlCommand
  class Context
    attr_accessor :error
    attr_reader :klass, :arguments

    delegate :chain?, to: :klass

    def initialize(klass, raise_errors: false, skip_unknown_parameters: false, **args_and_returns)
      @klass = klass
      @raise_errors = raise_errors.nil? ? false : raise_errors
      if chain?
        @called = []
        singleton_class.class_eval { attr_accessor :called } # TODO: Put this up by attr_accessor?
        arguments_and_returns_accessors(@klass.chain_arguments, @klass.chain_returns)
      else
        arguments_and_returns_accessors(@klass.arguments, @klass.returns)
      end

      assign_parameters(skip_unknown_parameters:, **args_and_returns)
    end

    def returns
      klass.returns.index_with { |rattr| send(rattr) }
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
      arguments.merge(returns)
    end

    def inspect
      "<GlCommand::Context '#{klass}' #{inspect_values}>"
    end

    def assign_parameters(skip_unknown_parameters: false, **args_and_returns)
      @permitted_keys ||= (@klass_arguments + @klass_returns).uniq

      args_and_returns.each do |arg, val|
        unless @permitted_keys.include?(arg) || skip_unknown_parameters
          raise ArgumentError, "Unknown argument or return attribute: '#{arg}'"
        end

        @arguments[arg] = val if @klass_arguments.include?(arg)
        send(:"#{arg}=", val) if @klass_returns.include?(arg)
      end
    end

    private

    def inspect_values
      [
        "success: #{success?}",
        "error: #{(error && "\"#{error}\"") || 'nil'}",
        "arguments: #{arguments}",
        "returns: #{returns}",
        chain? ? "called: #{called}" : nil
      ].compact.join(', ')
    end

    def arguments_and_returns_accessors(klass_arguments, klass_returns)
      @klass_returns = klass_returns
      @klass_returns.each do |arg|
        singleton_class.class_eval { attr_accessor arg }
      end
      @klass_arguments = klass_arguments
      @arguments = @klass_arguments.zip([]).to_h
    end
  end
end
