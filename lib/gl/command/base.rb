# frozen_string_literal: true

module GL
  # frozen_string_literal: true
  class Context
    attr_accessor :error
  #   def self.factory(klass)
  #     Struct.new('Context', :error, :failure, klass.returns)
  #   end
    def initialize(args)
      # Struct.new('Context', :error, :failure, self.class.returns)
      # super(args)
      # pp self.class
      @error = nil
      @do_not_raise = args[:do_not_raise]
      # @errors = ActiveModel::Errors.new(self)
    end

    def raise_error?
      !@do_not_raise
    end

    def fail!(error_message = nil)
      @failure = true
      error = error_message if error_message.present?
    end

    def failure?
      @failure || false
    end

    def success?
      !failure?
    end

    alias_method :successful?, :success?

    def inspect
      "<GL::Context success:#{success?} errors:#{@errors.full_messages} data:#{to_h}>"
    end
  end

  class Command
    # def self.included(base)
    #   base.class_eval do
    #     attr_reader :context
    #   end
    # end

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
            raise "what is this? #{param}"
          end
        end
        @parameters = parameters
      end

      def call(**args)
        opts = {
          do_not_raise: !!args.delete(:do_not_raise)
        }
        new(opts).perform_call(args)
      end

      private

      def priv_instance
        @priv_instance ||= new
      end
    end

    def initialize(context = {})
      @context = GL::Context.new(context)
    end

    def perform_call(**args)
      # run_callbacks :call do
        call(args)
    #   end
    rescue Exception => e
      rollback
      if context.raise_error?
        raise e
      else
        context.error = e
        context.fail!
      end
    end

    def rollback; end
  end
end
