# frozen_string_literal: true

require 'gl_command/rspec/matchers'

# A shared context to automatically set the subject of a spec to the
# described class. This allows `is_expected` to work directly on the
# command class in specs with `type: :command`.
RSpec.shared_context 'GLCommand::Command subject' do
  subject { described_class }
end

RSpec.configure do |config|
  # Makes the matcher methods (require, allow, returns) available in these specs.
  config.include GLCommand::Matchers, type: :command

  # Allows `is_expected` to work directly on the command class.
  config.include_context 'GLCommand::Command subject', type: :command
end
