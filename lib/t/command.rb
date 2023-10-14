# frozen_string_literal: true

class ContractFailure < StandardError; end
class ContextFailure < StandardError; end

require 'active_record'
require 'rails/railtie'

require 't/command/base'
require 't/command/chain'
require 't/command/context'
require 't/command/contract'
require 't/command/version'
