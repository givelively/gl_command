# frozen_string_literal: true

module GlCommand
  class Chain < GlCommand::Base
    UNCHAINED_MESSAGE = '#chain method not called in GlCommand::Chain #call. ' \
                        "The #call method *must* include 'chain(args)' or 'super' for chaining to take place!"

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

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def chain(args)
      @chain_called = true
      context.assign_parameters(**args)
      self.class.commands.each do |command|
        cargs = context.to_h.slice(*command.arguments).merge(raise_errors: context.raise_errors?)
        result = command.call(**cargs)
        context.assign_parameters(skip_unknown_parameters: true, **result.returns)

        if result.success?
          context.called << command
        else
          context.fail!(result.errors)
          break
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

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

      raise UNCHAINED_MESSAGE
    end
  end
end
