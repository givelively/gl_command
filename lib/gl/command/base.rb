# frozen_string_literal: true

module GL
  # frozen_string_literal: true
  # class Context < Struct
  #   def self.factory(klass)
  #     Struct.new('Context', :error, :failure, klass.returns)
  #   end
  #   def initialize(args)
  #     Struct.new('Context', :error, :failure, self.class.returns)
  #     # super(args)
  #     pp self.class
  #     @error = nil
  #     @do_not_raise = args[:do_not_raise]
  #     # @errors = ActiveModel::Errors.new(self)
  #   end

  #   def raise_error?
  #     !@do_not_raise
  #   end

  #   def fail!
  #     @failure = true
  #   end

  #   def failure?
  #     @failure || false
  #   end

  #   def success?
  #     !failure?
  #   end

  #   alias_method :successful?, :success?

  #   def inspect
  #     "<GL::Context success:#{success?} errors:#{@errors.full_messages} data:#{to_h}>"
  #   end
  # end

  class Command
    def self.included(base)
      base.class_eval do
        attr_reader :context
      end
    end

    class << self
      def returns(*return_attrs)
        @returns ||= return_attrs
      end

      def call(**args)
        pp args
        opts = {}
        opts[:do_not_raise] = !!args.delete(:do_not_raise)
        opts
        new(opts).perform(args)
      end
    end

    def initialize(context = {})
      @context = Context.factory(context)
    end

    def perform(**args)
      # run_callbacks :call do
        call(args)
    #   end
    # rescue Exception => e
    #   rollback
    #   if context.raise_error?
    #     raise e
    #   else
    #     context.error = e
    #     context.fail!
    #   end
    end

    def rollback; end
  end
end
