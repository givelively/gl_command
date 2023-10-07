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

  spec.required_ruby_version = '>= 3.0.4'
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

  spec.add_development_dependency 'database_cleaner', '~> 2.0.1'
  spec.add_development_dependency 'factory_bot', '~> 6.2.1'
  spec.add_development_dependency 'pg', '~> 1.4.1'
  spec.add_development_dependency 'prettier', '~> 3.1.2'
  spec.add_development_dependency 'rails', '~> 6.0.5.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'rspec-rails', '~> 5.1.2'
  spec.add_development_dependency 'rubocop', '~> 1.30'
  spec.add_development_dependency 'rubocop-performance', '~> 1.14'
  spec.add_development_dependency 'rubocop-rails', '~> 2.15.2'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.12'
  spec.add_development_dependency 'simplecov', '~> 0.16'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
