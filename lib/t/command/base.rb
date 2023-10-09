# frozen_string_literal: true

module T
  module Command
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include ActiveSupport::Callbacks

        define_callbacks :call
        attr_reader :context
      end
    end

    module ClassMethods
      %i[before around after].each do |hook|
        define_method(hook) do |method_or_block|
          set_callback(:call, hook, method_or_block)
        end
      end

      def call(context = {})
        new(context).tap(&:perform).context
      end
    end

    def initialize(context = {})
      @context = Context.factory(context)
    end

    def perform
      run_callbacks :call do
        call
      end
    rescue StandardError => e
      context.fail!
      context.errors.add(:base, e)
      rollback
    end

    def rollback; end
  end
end
