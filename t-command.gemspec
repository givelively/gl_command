# frozen_string_literal: true

require File.expand_path('lib/t/command/version', __dir__)

Gem::Specification.new do |spec|
  spec.name = 't-command'
  spec.version = T::Command::VERSION
  spec.authors = ['Tim Lawrenz']
  spec.summary = 'Implementation of the Command Pattern'
  spec.homepage = 'https://github.com/timlawrenz/t-command'
  spec.license = 'Apache'
  spec.platform = Gem::Platform::RUBY

  spec.required_ruby_version = '>= 2.7.3'
  spec.extra_rdoc_files = ['README.md']
  spec.files =
    Dir[
      'README.md',
      'LICENSE',
      'CHANGELOG.md',
      'lib/**/*.rb',
      'lib/**/*.erb',
      'lib/**/*.rake',
      't-command.gemspec',
      '.github/*.md',
      'Gemfile',
      'Rakefile'
    ]
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 3.2.0'
  spec.add_dependency 'activesupport', '>= 3.2.0'
  spec.add_dependency 'railties', '>= 3.2.0'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
