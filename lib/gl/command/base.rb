# frozen_string_literal: true

module GL
  class Context
    attr_accessor :error

    def initialize(klass, do_not_raise: false)
      @klass = klass
      @error = nil
      @do_not_raise = !!do_not_raise
      klass.returns.each do |arg|
        # It would be nice to have per-command context classes, and define attr_accessor on the class,
        # (rather than on each instance)
        singleton_class.class_eval { attr_accessor arg }
      end
    end

    def raise_error?
      !@do_not_raise
    end

    def fail!(passed_error = nil)
      @failure = true
      self.error = passed_error if passed_error
      self # Return self
    end

    def failure?
      @failure || false
    end

    def success?
      !failure?
    end

    alias_method :successful?, :success?

    def inspect
      "<GL::Context '#{@klass}' success: #{success?}, error: #{error}, returns:??>"
    end
  end

  class Command
    attr_accessor :context

    class << self
      def returns(*return_attrs)
        @returns ||= return_attrs
      end

      def arguments
        return @parameters if defined?(@parameters)
        parameters = {}
        priv_instance.method(:call).parameters.each do |param|
          case param[0]
          when :req, :opt
            raise "#{name} `call` method only supports keyword arguments (not '#{param[1]}' positional)"
          when :key
            parameters[:optional] ||= []
            parameters[:optional] << param[1]
          when :keyreq
            parameters[:required] ||= []
            parameters[:required] << param[1]
          else
            raise "what is this? #{param}" # TODO: are there other options??
          end
        end
        @parameters = parameters
      end

      def call(**args)
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
    rescue Exception => e
      rollback
      if @context.raise_error?
        raise e
      else
        @context.fail!(e)
      end
    end

    def rollback; end
  end
end
