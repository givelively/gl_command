# frozen_string_literal: true

class ContractFailure < StandardError; end
class ContextFailure < StandardError; end

require 'active_record'
require 'rails/railtie'

require 'gl/command/base'
