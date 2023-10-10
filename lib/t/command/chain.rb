# frozen_string_literal: true

module T
  module Chain
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include Command

        @links = [] if @links.blank?
        @links_called = [] if @links_called.blank?
      end
    end

    module ClassMethods
      def chain(foo)
        @links << foo
      end
    end

    def perform
      run_callbacks :call do
        links = self.class.instance_variable_get(:@links)
        links_called = self.class.instance_variable_get(:@links_called)

        links.each do |chainlink|
          links_called << chainlink
          chainlink.call(context)
        end
      end
    rescue StandardError
      rollback
    end

    def rollback
      @links_called.reverse.map(&:rollback)
    end
  end
end
