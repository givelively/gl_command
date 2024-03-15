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
    watch(%r{^lib/(.+)\.rb$}) { |m| "spec/lib/#{m[1]}_spec.rb" }
  end
end
