# frozen_string_literal: true

require_relative 'lib/gl_command/version'

Gem::Specification.new do |spec|
  spec.name = 'gl_command'
  spec.version = GLCommand::VERSION
  spec.authors = ['Give Lively']
  spec.summary = 'Give Lively Commands'
  spec.homepage = 'https://github.com/givelively/gl_command'
  spec.license = 'Apache-2.0'
  spec.platform = Gem::Platform::RUBY

  spec.required_ruby_version = '>= 3.1'
  spec.extra_rdoc_files = ['README.md']
  spec.files = %w[gl_command.gemspec README.md LICENSE] + `git ls-files | grep -E '^(lib)'`.split("\n")

  spec.add_dependency 'activerecord', '>= 3.2.0'
  spec.add_dependency 'gl_exception_notifier', '>= 1.0.2'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
