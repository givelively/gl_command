# frozen_string_literal: true

module GLCommand
  class Chainable < GLCommand::Callable
    UNCHAINED_MESSAGE = '#chain method not called in GLCommand::Chainable #call. ' \
                        "The #call method *must* include 'chain(args)' or 'super' " \
                        'for chaining to take place!'

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

      def chain_arguments_and_returns(*)
        (chain_arguments + chain_returns).uniq.zip([]).to_h
      end

      def chain_arguments
        @chain_arguments ||= commands.map(&:arguments).flatten.uniq
      end

      def chain_returns
        @chain_returns ||= commands.map(&:returns).flatten.uniq
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def chain(args)
      return if @chain_skipped

      @chain_called = true
      context.assign_parameters(**args)

      commands.map do |command|
        cargs = context.chain_arguments_and_returns.slice(*command.arguments)
                       .merge(context.opts_hash).merge(in_chain: true)

        result = command.call(**cargs)
        context.assign_parameters(skip_unknown_parameters: true, **result.returns)

        if result.success?
          context.called << command
        else
          @notified = true # chained command already notified
          errors.merge!(result.errors)
          stop_and_fail!(result.error, no_notify: result.no_notify?)
          break
        end
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def commands
      self.class.commands
    end

    def chain_rollback
      context.called.reverse_each do |command|
        chain_params = context.chain_arguments_and_returns
                              .slice(*command.arguments_and_returns)

        command.new(command.build_context(**chain_params)).rollback
      end
    end

    def call(**args)
      chain(args)
    end

    def skip_chain
      @chain_skipped = true
    end

    private

    def raise_unless_chained_or_skipped
      return if @chain_called || @chain_skipped

      raise UNCHAINED_MESSAGE
    end
  end
end
