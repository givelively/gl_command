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
        cargs = command.arguments.index_with { |arg| context.return_or_argument(arg) }

        result = command.call(**cargs.merge(raise_errors: context.raise_errors?))

        command.returns.each do |creturn|
          context.send(:"#{creturn}=", result.send(creturn))
        end
        if result.success?
          context.called << command
        else
          context.fail!(result.error)
          break
        end
      end
    end

    def chain_rollback
      context.called.reverse_each do |command|
        c_context = command.context(**context.to_h.slice(command.arguments_and_returns))
        command.new(c_context).rollback
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
