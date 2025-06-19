# frozen_string_literal: true

class ArrayAdd < GLCommand::Callable
  requires :array, :item
  returns :new_array
  def call; end
  def do_another_thing; end
  def rollback; end
end

class ArrayPop < GLCommand::Callable
  requires :array
  returns :popped_array, :popped_item
  validates_with :ArrayHasNoNilValidator
  def call; end
end

class ArrayStopAndFail < GLCommand::Chainable
  requires :array
  def call; end
end

class ArrayChain < GLCommand::Chainable
  requires :array, :item
  returns :new_array, :popped_array, :revised_item, :is_in_chain
  chain ArrayAdd, ArrayPop
  def call; end
  def rollback; end
end

class ArrayHasNoNilValidator < ActiveModel::Validator
  def validate(record)
    return if record.array.is_a?(Array) && record.array.none?(&:blank?)

    record.errors.add(:array, 'Must be an array with no blank items!')
  end
end

class TestNpo
  include ActiveModel::Validations
  attr_accessor :ein, :id
  def initialize(ein:); @ein = ein; @id = 1; end
  def self.destroy_all; end
end

class TestNormalizeEin < GLCommand::Callable
  requires string: String
  returns :ein
  def call; end
end

class CreateTestNpo < GLCommand::Callable
  requires :ein
  returns :test_npo
  def call; end
end

class CreateNormalizedTestNpo < GLCommand::Chainable
  requires :string
  returns :test_npo
  chain TestNormalizeEin, CreateTestNpo
end

class ChainClass1 < GLCommand::Callable
  requires :obj
  returns :obj_1
  def call; end
  def rollback; end
end

class ChainClass2 < GLCommand::Callable
  requires :obj_1
  returns :obj_2
  def call; end
  def rollback; end
end

class ChainClass3 < GLCommand::Callable
  requires :obj_2
  returns :obj_3
  def call; end
  def rollback; end
end

class TestChainable < GLCommand::Chainable
  requires :obj
  allows :fail_message
  returns :obj_3
  chain ChainClass1, ChainClass2, ChainClass3
end

class TestInstrumentTriggers < GLCommand::Callable
  requires :instruments_triggered
  allows :fail_error
  def call; end
end

class CumulativeDefinitionCommand < GLCommand::Callable
  requires :req1
  requires req2: String

  allows :allow1
  allows allow2: Integer

  returns :ret1
  returns :ret2

  def call; end
end
