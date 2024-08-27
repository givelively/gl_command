# frozen_string_literal: true

require 'active_support/core_ext/module'
require 'gl_exception_notifier'
require 'gl_command/validatable'

module GLCommand
  class Callable
    DEFAULT_OPTS = { raise_errors: false, skip_unknown_parameters: true, in_chain: false }.freeze
    RESERVED_WORDS = (DEFAULT_OPTS.keys + GLCommand::ChainableContext.reserved_words).sort.freeze

    class << self
      # Make raise_errors and skip_unknown_parameters reserved and raise if they're passed in
      def call(*posargs, **args)
        if arguments_and_returns.intersect?(RESERVED_WORDS)
          raise ArgumentError,
                "You used reserved word(s): #{arguments_and_returns & RESERVED_WORDS}\n" \
                '(check GLCommand::Callable::RESERVED_WORDS for the full list)'
        end

        if posargs.any?
          raise ArgumentError,
                "`call` only supports keyword args, not positional - you passed: '#{posargs}'"
        end

        # DEFAULT_OPTS contains skip_unknown_parameters: true - so it raises on call
        # (rather than in context initialize) to make errors more legible
        opts = DEFAULT_OPTS.merge(raise_errors: args.delete(:raise_errors)).compact
        # args are passed in in perform_call(args) so that invalid args raise in a legible place
        new(build_context(**args.merge(opts))).perform_call(args)
      end

      def call!(*posargs, **args)
        call(*posargs, **args.merge(raise_errors: true))
      end

      def build_context(raise_errors: false, skip_unknown_parameters: false,
                        **arguments_and_returns)
        context_class.new(self, raise_errors:, skip_unknown_parameters:, **arguments_and_returns)
      end

      def requires(*attributes, **strong_attributes)
        @requires ||= strong_args_hash(*attributes, **strong_attributes).freeze
      end

      def allows(*attributes, **strong_attributes)
        @allows ||= strong_args_hash(*attributes, **strong_attributes).freeze
      end

      def returns(*attributes, **strong_attributes)
        # NOTE: Because returns aren't validated, we don't store the types (only store keys)
        @returns ||= strong_args_hash(*attributes, **strong_attributes).keys.freeze
      end

      # arguments are what's passed to the .call command (the allows and requires)
      def arguments
        return @arguments if defined?(@arguments)

        duplicated_keys = requires.keys & allows.keys
        raise "Duplicated: #{duplicated_keys} - in both requires and allows" if duplicated_keys.any?

        @arguments = (requires.keys + allows.keys).freeze

        delegate(*@arguments + returns, to: :context)
        @arguments
      end

      # arguments_and_returns is just the keys (names) of the arguments and returns
      def arguments_and_returns
        (arguments + returns).uniq
      end

      # Used internally by GLCommand (probably don't reference in your own GLCommands)
      # is true in GLCommand::Chainable
      def chain?
        false
      end

      def rescue_from(error_class, with:)
        error_handlers[error_class] = with
      end

      def error_handlers
        @error_handlers ||= {}
      end

      private

      def context_class
        chain? ? GLCommand::ChainableContext : GLCommand::Context
      end

      def strong_args_hash(*attributes, **strong_attributes)
        # Convert attributes to strong attributes with nil value
        attributes.index_with { nil }.merge(strong_attributes)
      end
    end

    include GLCommand::Validatable

    attr_reader :context

    def initialize(context = nil)
      @context = context
    end

    def perform_call(args)
      raise_for_invalid_args!(**args)
      call_with_callbacks
      raise_unless_chained_or_skipped if self.class.chain? # defined in GLCommand::Chainable
      context.failure? ? handle_failure : context
    rescue StandardError => e
      handle_failure(e)
    end

    def stop_and_fail!(passed_error = nil, no_notify: false)
      # manually setting instance_variable because @no_notify shouldn't be updated in commands
      # (e.g. context shouldn't have an attr_writer)
      context.instance_variable_set(:@no_notify, no_notify)
      context.error = passed_error

      raise context.no_notifiable_error_to_raise # See comment in #handle_failure
    end

    # define a rollback method if you want to have actions for rolling back
    # it is called in handle_failure
    def rollback; end

    # Ensure that call is overridden in subclass
    def call
      raise 'You must define the `call` instance method on your GLCommand'
    end

    private

    # trigger: [:before_call, :before_rollback]
    def instrument_command(trigger)
      # Override where gem is used if you want to instrument commands
    end

    # rubocop:disable Metrics/AbcSize
    def handle_failure(e = nil)
      context.error ||= e

      call_rollbacks

      # Don't call GLExceptionNotifier if:
      # - already notified
      # - raise_errors: true (because raising error will call sentry)
      # - context.no_notify?
      unless @notified || context.raise_errors? || context.no_notify?
        GLExceptionNotifier.call(context.error)
        @notified = true
      end

      return context unless context.raise_errors?

      # NOTE: this is tricksy. Exception#cause stores the previous error that was raised.
      # If we are in no_notify, raise CommandNoNotifyError first
      # Then raise the original error (so that the error is just the original error, with a #cause)
      # context.no_notify? checks error #cause - if it's CommandNoNotifyError, the context is no_notify
      # This is so validation errors in chainables don't call GLExceptionNotifier
      raise context.no_notifiable_error_to_raise
    rescue GLCommand::CommandNoNotifyError
      raise context.error # makes CommandNoNotifyError the cause
    end

    def call_with_callbacks
      GLExceptionNotifier.breadcrumbs(data: { context: context.inspect }, message: self.class.to_s)
      instrument_command(:before_call)
      validate_validatable! # defined in GLCommand::Validatable

      # This is the where the call actually happens
      assign_returns(call)
    rescue StandardError => e
      handler = self.class.error_handlers[e.class]
      handler ? send(handler, e) : raise(e)
    end

    def assign_returns(returned)
      return if returned.is_a?(context.class) # prevent looping assignment
      # Naive assign of the return. Only assigns if not already assigned, and if a single item
      # Could be made to accept a hash instead and assign based on that...
      return unless self.class.returns.count == 1 && context.returns[self.class.returns.first].nil?

      context.assign_parameters(self.class.returns.first => returned)
    end
    # rubocop:enable Metrics/AbcSize

    def call_rollbacks
      return if defined?(@rolled_back) # Not sure this is required

      instrument_command(:before_rollback)

      @rolled_back = true

      chain_rollback if self.class.chain? # defined in GLCommand::Chainable
      rollback
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def raise_for_invalid_args!(**args)
      missing = (self.class.requires || {}).keys - args.keys
      raise ArgumentError, "missing #{error_keys_str(missing)}" if missing.any?

      unknown = args.keys - self.class.arguments - DEFAULT_OPTS.keys
      raise ArgumentError, "unknown #{error_keys_str(unknown)}" if unknown.any?

      # strong_attributes type checking
      self.class.requires.merge(self.class.allows).each do |arg, type|
        next if type.nil? || args[arg].is_a?(type)
        # Validation skipped if allows and nil (but not if blank)
        next if args[arg].nil? && self.class.allows.include?(arg)

        raise GLCommand::ArgumentTypeError, ":#{arg} is not a #{type}"
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def error_keys_str(keys)
      "keyword#{keys.count > 1 ? 's' : ''}: #{keys.map { |k| ":#{k}" }.join(', ')}"
    end
  end
end
