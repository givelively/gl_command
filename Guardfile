# frozen_string_literal: true

directories %w[lib spec bin]

rspec_options = {
  cmd: 'bundle exec rspec',
  all_after_pass: false,
  all_on_start: false,
  failed_mode: :focus
}

group :red_green_refactor, halt_on_fail: true do
  guard :rspec, rspec_options do
    watch('spec/spec_helper.rb') { 'spec' }
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/gl/command/(.+)\.rb$}) { |m| "spec/gl/#{m[1]}_spec.rb" }
  end
end
