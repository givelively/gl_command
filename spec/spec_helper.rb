# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require 'gl_command'
require 'active_record'

# Load all ruby files in spec/support
Dir.glob(File.join(__dir__, 'support', '**', '*.rb')).sort.each { |f| require f }
