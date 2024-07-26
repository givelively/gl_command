# frozen_string_literal: true

require 'g_l_command/context'
require 'g_l_command/chainable_context'
require 'g_l_command/callable'
require 'g_l_command/chainable'
require 'g_l_command/validatable'

module GLCommand
  class ArgumentTypeError < StandardError; end

  class StopAndFail < StandardError; end

  # NOTE: CommandNoNotifyError should not be the final error raised,
  # It should be the #cause for the final error raised. See callable#handle_failure
  class CommandNoNotifyError < StandardError; end
end
