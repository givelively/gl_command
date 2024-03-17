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
        @arguments ||= new.method(:call).parameters.map do |param|
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

    def initialize(context=nil)
      @context = context if context
    end

    def perform_call(args)
      assign_and_call(args)
      @context
    rescue StandardError => e
      chain_rollback if self.class.chain?
      rollback
      raise e if @context.raise_errors?

      @context.fail!(e)
    end

    def rollback; end

    private

    def assign_and_call(args)
      call(**args)
    end
  end
end
