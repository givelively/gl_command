# frozen_string_literal: true

require 'English'
# TODO: can we use forwardable instead of ActiveSupport delegate ?
require 'active_support/core_ext/module'

module GLCommand
  class Context
    def initialize(klass, raise_errors: false, skip_unknown_parameters: false,
                   **arguments_and_returns)
      @klass = klass
      @raise_errors = raise_errors.nil? ? false : raise_errors
      @klass.arguments_and_returns.each { |key| singleton_class.class_eval { attr_accessor key } }
      initialize_chain_context(**arguments_and_returns) if chain?
      assign_parameters(skip_unknown_parameters:, **arguments_and_returns)
    end

    # TODO: figure out a different place to pass skip_unknown_parameters than initialize,
    # it doesn't make sense to include in the opts hash
    def opts_hash
      { raise_errors: raise_errors? }
    end

    attr_reader :klass, :error
    attr_writer :full_error_message

    delegate :errors, to: :@callable, allow_nil: true

    def chain?
      false
    end

    def returns
      @klass.returns.index_with { |rattr| send(rattr) }
    end

    def arguments
      @klass.arguments.index_with { |rattr| send(rattr) }
    end

    def raise_errors?
      @raise_errors
    end

    def failure?
      @failure || errors.present? || @full_error_message.present? || false
    end

    def success?
      !failure?
    end

    # @no_notify is set by passing no_notify into stop_and_fail!
    # If a command is no_notify within another command call!, inside_no_notify_error? is true
    def no_notify?
      @no_notify.presence || inside_no_notify_error?
    end

    def full_error_message
      return nil if @full_error_message.blank? && error.blank?

      ContextInspect.error(defined?(@full_error_message) ? @full_error_message : @error)
    end

    alias_method :successful?, :success?

    def to_h
      arguments.merge(returns)
    end

    # Set up to make errors visible when specs fail
    def inspect
      "<#{self.class.name} #{inspect_values.join(', ')}, class=#{klass}>"
    end

    def assign_parameters(skip_unknown_parameters: false, **arguments_and_returns)
      arguments_and_returns.each do |arg, val|
        assign_parameter_val(arg, val, skip_unknown_parameters:)
      end
    end

    # This is what makes validation work
    def assign_callable(callable)
      @callable = callable
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def error=(passed_error = nil)
      @failure = true

      @error =
        if exception?(passed_error)
          # This catches errors within GLCommand::Context and prevents self referential error display
          # $ERROR_INFO (aka $!), stores the last Ruby error
          if $ERROR_INFO.to_s.include?('for <GLCommand::Context')
            @full_error_message ||= $ERROR_INFO.to_s
          end
          # If something raised ActiveRecord::RecordInvalid, assign its errors to #errors
          merge_errors(passed_error.record.errors) if
            passed_error.is_a?(ActiveRecord::RecordInvalid) && defined?(passed_error.record.errors)
          # Return a new error if it's an error (rather than the class)
          passed_error.is_a?(Class) ? passed_error.new(@full_error_message) : passed_error
        elsif errors.present? # check for validation errors
          # Assign ActiveRecord::RecordInvalid if validatable error
          ActiveRecord::RecordInvalid.new(@callable)
        else
          @full_error_message ||= passed_error if passed_error.present?
          GLCommand::StopAndFail.new(passed_error || @full_error_message)
        end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def no_notifiable_error_to_raise
      if no_notify? && !inside_no_notify_error?
        GLCommand::CommandNoNotifyError.new(full_error_message)
      else
        error
      end
    end

    private

    def exception?(passed_error)
      passed_error.is_a?(Exception) ||
        (passed_error.respond_to?(:ancestors) && passed_error.ancestors.include?(Exception))
    end

    def inside_no_notify_error?
      @error.present? && @error.respond_to?(:cause) && @error.cause.present? &&
        @error.cause.is_a?(GLCommand::CommandNoNotifyError)
    end

    def merge_errors(new_errors)
      # When merging the errors, don't add duplicate errors
      new_errors.each do |new_error|
        errors.import(new_error) unless errors&.full_messages&.include?(new_error.full_message)
      end
    end

    # Overridden in ChainableContext
    def assignable_parameters
      @klass.arguments_and_returns
    end

    # Overridden in ChainableContext
    def assign_parameter_val(arg, val, skip_unknown_parameters:)
      if assignable_parameters.include?(arg)
        # if required because chain_arguments_and_returns are assignable_parameters
        send(:"#{arg}=", val) if @klass.arguments_and_returns.include?(arg)
      elsif !skip_unknown_parameters
        raise ArgumentError, "Unknown argument or return attribute: '#{arg}'"
      end
    end

    # Overridden in ChainableContext
    def inspect_values
      [
        "error=#{success? ? 'nil' : full_error_message}",
        "success=#{success?}",
        "arguments={#{::GLCommand::ContextInspect.hash_params(arguments)}}",
        "returns={#{::GLCommand::ContextInspect.hash_params(returns)}}"
      ]
    end
  end
end
