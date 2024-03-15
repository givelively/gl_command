# frozen_string_literal: true

module GlCommand
  class Chain < GlCommand::Base
    class << self
      def chain?
        true
      end

      def chain(*commands)
        @commands = commands.flatten
      end

      def commands
        @commands || []
      end

      def chain_arguments
        @chain_arguments ||= (arguments + commands.map(&:arguments)).flatten.uniq
      end

      def chain_returns
        @chain_returns ||= (returns + commands.map(&:returns)).flatten.uniq
      end

      def args_and_returns
        @args_and_returns ||= (returns + arguments + commands.map(&:args_and_returns)).flatten.uniq
      end
    end

    def chain(args)
      self.class.commands.each do |command|
        context.called << command
        cargs = command.arguments.map { |arg| [arg, context.send(arg)] }.to_h

        result = command.call(**cargs.merge(raise_errors: context.raise_errors?))

        command.returns.each do |creturn|
          context.send("#{creturn}=", result.send(creturn))
        end
        next if result.success?

      end
    end

    def chain_rollback
      # TODO: test this
      context.called.reverse.each do |command|
        c_instance = command.new

        command.args_and_returns.each do |arg|
          c_instance.context.send("#{arg}=", context.send(arg))
        end
        c_instance.rollback
      end
    end

    def call(args)
      chain(**args)
    end

    private

    def assign_and_call(args)
      # Assign the args to the
      args.each { |k, v| @context.assign(k, v) }
      call(**args)
      chain(**args)
    end
  end
end
