# frozen_string_literal: true

class ContractFailure < StandardError; end
class ContextFailure < StandardError; end

require 'active_record'
require 'rails/railtie'

require 'gl/command/base'
# require 'gl/command/chain'
# require 'gl/command/context'
# require 'gl/command/contract' 
require 'gl/command/version'
