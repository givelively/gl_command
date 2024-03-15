# frozen_string_literal: true

module GlCommand
  class Base
    attr_reader :context

    class << self
      def returns(*return_attrs)
        @returns ||= return_attrs
      end

      def arguments
        @arguments ||= new(no_context: true).method(:call).parameters.map do |param|
          param[1]
        end
      end

      def args_and_returns
        returns + arguments
      end

      def call(*posargs, **args)
        if posargs.any?
          raise ArgumentError, "`call` only supports keyword arguments, not positional - you passed: '#{posargs}'"
        end

        raise_errors = args.delete(:raise_errors)
        opts = raise_errors.nil? ? {} : { raise_errors: }
        new(**opts).perform_call(args)
      end

      def call!(*posargs, **args)
        call(*posargs, **args.merge(raise_errors: true))
      end
    end

    def initialize(raise_errors: false, no_context: false)
      @context = GlCommand::Context.new(self.class, raise_errors:) unless no_context
    end

    def perform_call(args)
      assign_and_call(args)
    rescue StandardError => e
      rollback
      raise e if @context.raise_errors?

      @context.fail!(e)
    end

    def rollback; end

    private

    def assign_and_call(args)
      # Assign the args to the
      args.each { |k, v| @context.assign(k, v) }
      call(**args)
      @context
    end
  end
end
