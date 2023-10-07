# frozen_string_literal: true

module T
  class Context < OpenStruct
    def self.factory(context = {})
      return context if context.is_a?(Context)

      Context.new(context.merge({ errors: [] }))
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
  end
end
