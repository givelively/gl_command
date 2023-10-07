# frozen_string_literal: true

module T
  module Command
    def self.included(base)
      base.class_eval do
        extend ClassMethods

        attr_reader :context
      end
    end

    module ClassMethods
      def call(context = {})
        new(context).tap(&:perform).context
      end
    end

    def initialize(context = {})
      @context = Context.factory(context)
    end

    def perform
      call
    rescue StandardError => e
      context.fail!
      context.errors << e
      rollback
    end
  end
end
