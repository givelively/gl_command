# frozen_string_literal: true

module T
  module Chain
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include Command

        @commands = []
        @commands_called = []
      end
    end

    module ClassMethods
      def chain(command)
        @commands << command
      end
    end

    def perform
      run_callbacks :call do
        commands = self.class.instance_variable_get(:@commands)
        commands_called = self.class.instance_variable_get(:@commands_called)

        commands.each do |command|
          commands_called << command
          @context = command.call(@context)
        end
      end
    rescue StandardError
      rollback
    end

    def rollback
      @commands_called.reverse.map(&:rollback)
    end
  end
end
