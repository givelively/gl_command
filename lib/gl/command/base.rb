# frozen_string_literal: true

module GL
  class Command
    attr_accessor :context

    class << self
      def returns(*return_attrs)
        @returns ||= return_attrs
      end

      def arguments_hash
        return @arguments_hash if defined?(@arguments_hash)
        arguments = {optional: [], required: []}
        new(no_context: true).method(:call).parameters.each do |param|
          case param[0]
          when :key then arguments[:optional] << param[1]
          when :keyreq then arguments[:required] << param[1]
          else
            raise "`call` only supports keyword arguments, not #{param}"
          end
        end
        @arguments_hash = arguments
      end

      def arguments
        arguments_hash.values.flatten
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
      # no_context is a gross hack to prevent looping in #arguments
      unless no_context
        @context = GL::Context.new(self.class, raise_errors: raise_errors)
      end
    end

    def perform_call(args)
      call(**args)
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
