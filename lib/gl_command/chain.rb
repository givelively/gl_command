# frozen_string_literal: true

module GlCommand
  class Chain < GlCommand::Base
    class << self
      def chain(*commands)
        @commands = commands.flatten
      end

      def commands
        @commands || []
      end

      def args_and_returns
        @args_and_returns ||= (returns + arguments + commands.map(&:args_and_returns)).flatten.uniq
      end
    end

    def call(args)
      chain(**args)
    end

    def chain(args)
      self.class.commands.each do |command|
        pp command.arguments
        cargs = command.arguments.map { |arg| [arg, context.send(arg)] }.to_h
        pp cargs, cargs.merge(raise_errors: context.raise_errors?)
        result = command.call(**cargs.merge(raise_errors: context.raise_errors?))
        # pp "result: ", result
      end
    end
  end
end
