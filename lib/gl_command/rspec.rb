# frozen_string_literal: true

require 'gl_command/rspec/matchers'

# This guard ensures that the configuration is only applied if RSpec is
# actually loaded in the user's environment.
if defined?(RSpec)
  RSpec.configure do |config|
    # Makes the matcher methods (require, allow, return) available in these specs.
    config.include GLCommand::Matchers, type: :callable

    # Allows `is_expected` to work directly on the command class.
    config.define_derived_metadata(type: :callable) do |meta|
      meta[:subject] ||= described_class
    end
  end
end
