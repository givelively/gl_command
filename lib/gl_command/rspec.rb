# frozen_string_literal: true

require 'gl_command/rspec/matchers'

# This guard ensures that the configuration is only applied if RSpec is
# actually loaded in the user's environment.
if defined?(RSpec)
  # A shared context to automatically set the subject of a spec to the
  # described class. This allows `is_expected` to work directly on the
  # command class in specs with `type: :callable`.
  RSpec.shared_context 'GLCommand::Callable subject' do
    subject { described_class }
  end

  RSpec.configure do |config|
    # Makes the matcher methods (require, allow, returns) available in these specs.
    config.include GLCommand::Matchers, type: :callable

    # Allows `is_expected` to work directly on the command class.
    config.include_context 'GLCommand::Callable subject', type: :callable
  end
end
