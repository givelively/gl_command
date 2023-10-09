# frozen_string_literal: true

module T
  class Context < OpenStruct # rubocop:disable Style/OpenStructUse
    attr_writer :errors

    def self.factory(context = {})
      return context if context.is_a?(Context)

      Context.new(context)
    end

    def errors
      @errors ||= ActiveModel::Errors.new(self)
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
  end
end
