# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '.rubocop_rules.yml' do # rubocop:disable RSpec/DescribeClass
  rules_ruby_version = '3.2.4' # Update this when the rules are written with a new Ruby version

  # Don't match on patch version
  rules_version_matches = rules_ruby_version.split('.')[0..1] == RUBY_VERSION.split('.')[0..1]

  it "has the correct rules for Ruby: #{rules_ruby_version}", skip: !rules_version_matches do
    # If this spec failed, it's because Rubocop rules changed and you need to run:
    # bin/lint --write-rubocop-rules
    # (and commit the updated .rubocop_rules.yml)
    `bin/lint --write-rubocop-rules`
    # Verify that the file hasn't changed
    expect(`git diff --exit-code --ignore-space-change .rubocop_rules.yml`).to eq('')
  end
end
