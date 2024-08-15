# frozen_string_literal: true

require 'gl_command/context_inspect'
require 'gl_command/context'
require 'gl_command/chainable_context'
require 'gl_command/callable'
require 'gl_command/chainable'

module GLCommand
  class ArgumentTypeError < StandardError; end

  class StopAndFail < StandardError; end

  # NOTE: CommandNoNotifyError should not be the final error raised,
  # It should be the #cause for the final error raised. See callable#handle_failure
  class CommandNoNotifyError < StandardError; end
end
