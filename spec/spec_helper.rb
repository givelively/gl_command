# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require 't/command'
require 'active_record'

require 'simplecov'
SimpleCov.start 'rails' do
  add_filter 'spec/'
  add_filter '.github/'
  add_filter 'lib/generators/templates/'
  add_filter 'lib/t/command/version'
end
