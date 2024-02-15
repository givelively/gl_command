# frozen_string_literal: true

module GL
  class Command
    attr_reader :context

    include ActiveSupport::Callbacks
    define_callbacks :call

    class << self
      def returns(*return_attrs)
        @returns ||= return_attrs
      end

      def arguments
        @arguments ||= new(no_context: true).method(:call).parameters.map do |param|
          param[1]
        end
      end

      def call(*posargs, **args)
        if posargs.any?
          raise ArgumentError, "`call` only supports keyword arguments, not positional - you passed: '#{posargs}'"
        end

        raise_errors = args.delete(:raise_errors)
        opts = raise_errors != nil ? {raise_errors: raise_errors} : {}
        new(**opts).perform_call(args)
      end

      def call!(*posargs, **args)
        call(*posargs, **args.merge(raise_errors: true))
      end
    end

    def initialize(raise_errors: false, no_context: false)
      @context = GL::Context.new(self.class, raise_errors: raise_errors) unless no_context
    end

    def perform_call(args)
      run_callbacks :call do
        call(**args)
      end
      @context
    rescue StandardError => e
      rollback
      raise e if @context.raise_errors?

      @context.fail!(e)
    end

    def rollback; end
  end

  class CommandChain < Command
  end
end
