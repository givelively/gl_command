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

      def arguments_and_returns
        @arguments_and_returns ||= (returns + arguments + commands.map(&:arguments_and_returns)).flatten.uniq
      end
    end

    def chain(args)
      @chain_called = true
      context.assign_parameters(**args)
      self.class.commands.each do |command|
        context.called << command
        cargs = command.arguments.index_with { |arg| context.return_or_argument(arg) }

        result = command.call(**cargs.merge(raise_errors: context.raise_errors?))

        command.returns.each do |creturn|
          context.send(:"#{creturn}=", result.send(creturn))
        end
        next if result.success?
        # Need to add error to the parent here
      end
    end

    def chain_rollback
      return
      # TODO: test this
      context.called.reverse_each do |command|
        c_instance = command.new

        command.arguments_and_returns.each do |arg|
          c_instance.context.send(:"#{arg}=", context.send(arg))
        end
        c_instance.rollback
      end
    end

    def call(args)
      chain(**args)
    end

    private

    def raise_unless_chained
      return if @chain_called

      raise "#chain method not called in GlCommand::Chain #call. The #call method *must* include 'chain(args)' or 'super' for chaining to take place!"
    end
  end
end
