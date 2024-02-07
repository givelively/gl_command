# frozen_string_literal: true

module GL
  # class NotAContextError < ArgumentError; end

  class Context #< Struct
    # include ActiveModel::Validations

    # attr_accessor :error

    # def self.factory(context = {})
    #   return context if context.is_a?(Context)
    #   raise NotAContextError, 'Arguments are not a Context.' unless context.respond_to?(:each_pair)

    #   Context.new(context)
    # end

    def initialize(args)
      # Struct.new('Context', :error, :failure, self.class.returns)
      # # super(args)
      # pp self.class
      # @error = nil
      # @do_not_raise = args[:do_not_raise]
      # @errors = ActiveModel::Errors.new(self)
    end

    def raise_error?
      !@do_not_raise
    end

    def fail!
      @failure = true
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
end
