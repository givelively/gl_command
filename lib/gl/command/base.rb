# frozen_string_literal: true

module GL
  class Command
    attr_accessor :context

    class << self
      def returns(*return_attrs)
        @returns ||= return_attrs
      end

      def call(*posargs, **args)
        if posargs.any?
          raise ArgumentError, "`call` only supports keyword arguments, not positional - you passed: '#{posargs}'"
        end

        opts = {
          do_not_raise: args.delete(:do_not_raise)
        }
        new(opts).perform_call(args)
      end

      private

      def priv_instance
        @priv_instance ||= new
      end
    end

    def initialize(context_opts = {})
      @context = GL::Context.new(self.class, **context_opts)
    end

    def perform_call(args)
      call(**args)
      @context
    rescue StandardError => e
      rollback
      raise e if @context.raise_error?

      @context.fail!(e)
    end

    def rollback; end
  end

  class CommandChain < Command
  end
end
