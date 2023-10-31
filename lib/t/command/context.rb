# frozen_string_literal: true

module T
  class Context < OpenStruct # rubocop:disable Style/OpenStructUse
    include ActiveModel::Validations

    attr_accessor :errors

    def self.factory(context = {})
      return context if context.is_a?(Context)

      Context.new(context)
    end

    def initialize(args)
      super(args)
      @errors = ActiveModel::Errors.new(self)
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

    def to_s
      "#<T::Context success:#{success?} errors:#{@errors.to_h} data:#{to_h}>"
    end
  end
end
