# frozen_string_literal: true

module T
  module Chain
    def self.included(base)
      base.class_eval do
        extend ClassMethods

        @commands = []
      end
    end

    module ClassMethods
      def chain(command)
        @commands << command
      end

      def commands
        @commands
      end
    end

    def commands
      self.class.commands
    end

    def perform
      run_callbacks :call do
        @commands_called = []
        commands.each { |command| call_command(command) }
      end
    rescue ContextFailure
      rollback
    end

    def rollback
      @commands_called.reverse_each do |command|
        command.new(@context).rollback
      end
    end

    def call_command(command)
      @commands_called << command
      @context = command.call(@context)
      raise ContextFailure if @context.failure?
    end
  end
end
