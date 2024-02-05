# frozen_string_literal: true

module GL
  module Command
    def self.included(base)
      base.class_eval do
        include ActiveSupport::Callbacks
        extend ClassMethods

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
    rescue ContractFailure
      context.fail!
      rollback
    rescue StandardError => e
      context.fail!
      context.errors.add(:base, e)
      rollback
    end

    def rollback; end
  end
end
