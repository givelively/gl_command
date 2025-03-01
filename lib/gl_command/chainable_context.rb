# frozen_string_literal: true

module GLCommand
  class ChainableContext < GLCommand::Context
    def self.reserved_words
      %i[callable called failure no_notify raise_errors] + instance_methods
    end

    # Called at the end of GLCommand::Context initialize
    def initialize_chain_context(**arguments_and_returns)
      @called = []
      @chain_arguments_and_returns = @klass.chain_arguments_and_returns(**arguments_and_returns)
    end

    attr_accessor :called

    def chain?
      true
    end

    def to_h
      arguments.merge(returns)
    end

    def chain_arguments_and_returns
      @chain_arguments_and_returns.merge(to_h)
    end

    private

    def inspect_values
      super + ["called=#{called}"]
    end

    def assignable_parameters
      @assignable_parameters ||=
        (@klass.arguments_and_returns + @chain_arguments_and_returns.keys).uniq.freeze
    end

    # Overrides Context method, called by assign_parameters
    def assign_parameter_val(arg, val, skip_unknown_parameters:)
      super
      @chain_arguments_and_returns[arg] = val if @chain_arguments_and_returns.key?(arg)
    end
  end
end
