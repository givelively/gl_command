# frozen_string_literal: true

module GlCommand
  class Base
    attr_reader :context

    class << self
      def chain?
        false
      end

      def context(raise_errors: false, skip_unknown_parameters: false, **args_and_returns)
        GlCommand::Context.new(self, raise_errors:, skip_unknown_parameters:, **args_and_returns)
      end

      def returns(*return_attrs)
        @returns ||= return_attrs
      end

      def arguments
        @arguments ||= new(nil).method(:call).parameters.map do |param|
          param[1]
        end
      end

      def arguments_and_returns
        (returns + arguments).uniq
      end

      def call(*posargs, **args)
        if posargs.any?
          raise ArgumentError, "`call` only supports keyword arguments, not positional - you passed: '#{posargs}'"
        end

        # skip_unknown_parameters: true so it raises on call (rather than in context initialize)
        raise_errors = args.delete(:raise_errors)
        opts = args.merge(raise_errors.nil? ? {} : { raise_errors: })
                   .merge(skip_unknown_parameters: true)

        new(context(**opts)).perform_call(args)
      end

      def call!(*posargs, **args)
        call(*posargs, **args.merge(raise_errors: true))
      end
    end

    # nil context passed in 'arguments' class method
    def initialize(context)
      @context = context
    end

    def perform_call(args)
      call_with_callbacks(args)
      raise_unless_chained if self.class.chain? # defined in GlCommand::Chain
      call_rollbacks if context.failure?
      @context
    rescue StandardError => e
      call_rollbacks
      raise e if @context.raise_errors?

      @context.fail!(e)
    end

    def rollback; end

    private

    # Separating this out so that it can be used to set callbacks
    def call_with_callbacks(args)
      call(**args)
    end

    def call_rollbacks
      return if defined?(@rolled_back) # Not sure this is required

      @rolled_back = true

      chain_rollback if self.class.chain? # defined in GlCommand::Chain
      rollback
    end
  end
end
