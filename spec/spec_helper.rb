# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require 'gl_command'
require 'gl_command/rspec'

Dir.glob(File.join(__dir__, 'support', '**', '*.rb')).sort.each { |f| require f }
