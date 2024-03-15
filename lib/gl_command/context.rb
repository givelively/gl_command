# frozen_string_literal: true

module GlCommand
  class Context
    attr_accessor :error
    attr_reader :arguments, :returns

    def initialize(klass, raise_errors: false)
      @klass = klass
      @raise_errors = raise_errors.nil? ? false : raise_errors
      if klass.chain?
        @called = []
        singleton_class.class_eval { attr_accessor :called }
        assign_args_and_returns(klass.chain_arguments, klass.chain_returns)
      else
        assign_args_and_returns(klass.arguments, klass.returns)
      end
      # # I would love to only assign returns...
      @class_attrs = klass.args_and_returns.uniq
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
      @class_attrs.sort.index_with { |cattr| send(cattr) }
    end

    def to_s
      inspect
    end

    def inspect
      "<GlCommand::Context '#{@klass}' success: #{success?}, error: #{error || 'nil'}, #{inspect_data}>"
    end

    def assign(cattr, val)
      return unless @arguments.include?(cattr)
      instance_variable_set("@#{cattr}", val)
    end

    private

    def inspect_data
      data = "data: #{to_h}"
      @klass.chain? ? "called: #{called}, #{data}" : data
    end

    def assign_args_and_returns(arguments, returns)
      @returns = returns
      @returns.each do |arg|
        # It would be nice to have per-command context classes, and define attr_accessor on the class,
        # (rather than on each instance)
        singleton_class.class_eval { attr_accessor arg }
      end
      @arguments = arguments # TODO: Test for non chain
      (@arguments - @returns).each do |arg|
        singleton_class.class_eval { attr_reader arg }
      end
    end
  end
end
