# frozen_string_literal: true

class ArrayHasNoNilValidator < ActiveModel::Validator
  def validate(record)
    return if record.array.is_a?(Array) && record.array.none?(&:blank?)

    record.errors.add(:array, 'Must be an array with no blank items!')
  end
end

class ArrayAdd < GLCommand::Callable
  requires :array, :item
  returns :new_array

  def call
    do_another_thing # For testing rollbacks
    array.push(item)
    context.new_array = array.dup
    context
  end

  def do_another_thing; end

  def rollback
    array.delete(item)
  end
end

class ArrayPop < GLCommand::Callable
  requires :array
  returns :popped_array, :popped_item
  validates :array, presence: true
  validates_with ArrayHasNoNilValidator

  def call
    context.popped_item = array.pop
    context.popped_array = array
  end
end

class ArrayStopAndFail < GLCommand::Callable
  requires :array
  allows :no_notify_val

  def call
    stop_and_fail!('This command always fails!', no_notify: no_notify_val)
  end
end

class ArrayChain < GLCommand::Chainable
  requires :array, :item
  returns :new_array, :popped_array, :revised_item, :is_in_chain
  chain ArrayAdd, ArrayPop

  def call
    context.revised_item = item + 5
    # The return from `chain` is the context
    context.is_in_chain = chain(item: context.revised_item)
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

  def call
    context.ein = normalize(string)
  end

  private

  def normalize(ein)
    return nil unless ein.is_a?(String)
    # Remove all non-digits
    ein = ein.tr('^0-9', '')
    # Return if it's not the right length
    return ein unless ein.length == 9
    # Add the dash
    "#{ein[0..1]}-#{ein[2..-1]}"
  end
end

class CreateTestNpo < GLCommand::Callable
  requires :ein
  returns :test_npo

  def call
    context.test_npo = TestNpo.new(ein:)
  end
end

class CreateNormalizedTestNpo < GLCommand::Chainable
  requires :string
  returns :test_npo
  chain TestNormalizeEin, CreateTestNpo
end

class ChainClass1 < GLCommand::Callable
  requires :obj
  returns :obj_1

  def call
    obj.one = '1'
    context.obj_1 = obj
  end

  def rollback
    obj.one = '1-rolled'
  end
end

class ChainClass2 < GLCommand::Callable
  requires :obj_1
  allows :fail_message
  returns :obj_2

  def call
    if fail_message.present?
      context.error = fail_message
      return
    end
    obj_1.two = '2'
    context.obj_2 = obj_1
  end

  def rollback
    obj_1.two = '2-rolled'
  end
end

class ChainClass3 < GLCommand::Callable
  requires :obj_2
  returns :obj_3

  def call
    obj_2.three = '3'
    context.obj_3 = obj_2
  end

  def rollback
    obj_2.three = '3-rolled'
  end
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

  def call
    stop_and_fail!('fail_error is true') if fail_error
  end

  def instrument_command(trigger)
    instruments_triggered << trigger
  end
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
