# frozen_string_literal: true

class ArrayAdd < GLCommand::Callable
  requires :array, :item

  returns :new_array

  def call
    context.new_array = array.push(item).dup
    do_another_thing
  end

  def do_another_thing; end

  def rollback
    context.array.pop
  end
end

class ArrayHasNoNilValidator < ActiveModel::Validator
  def validate(record)
    return if record.array.is_a?(Array) && record.array.none?(&:blank?)

    record.errors.add(:array, 'Must be an array with no blank items!')
  end
end

# class ArrayPop < GLCommand::Validatable
class ArrayPop < GLCommand::Callable
  requires :array

  returns :popped_array, :popped_item

  validates :array, presence: true

  validates_with ArrayHasNoNilValidator

  def call
    context.popped_item = array.pop
    context.popped_array = array.dup
  end
end

class ArrayChain < GLCommand::Chainable
  requires :array, :item
  chain ArrayAdd, ArrayPop

  returns :new_array, :popped_array, :revised_item

  def call
    context.revised_item = item + 5

    chain(array:, item: context.revised_item)
  end

  def rollback
    context.revised_item = context.item - 3
  end
end

class TestNpo
  include ActiveModel::Validations
  extend ActiveModel::Callbacks

  def self.all
    @all ||= []
  end

  attr_reader :ein, :id

  validates_presence_of :ein

  define_model_callbacks :initialize, only: :after
  after_initialize :add_to_all_if_valid

  def initialize(ein:)
    run_callbacks :initialize do
      @ein = ein
      @id = TestNpo.all.count + 1
    end
  end

  # REALLY hacky validate uniqueness
  validates_each :ein do |record, attr, value|
    existing_test_npo = TestNpo.all.find { |n| n.ein == value }
    if existing_test_npo && existing_test_npo&.id != record.id
      record.errors.add attr,
                        'EIN already taken'
    end
  end

  def add_to_all_if_valid
    return if invalid?

    TestNpo.all << self
  end
end

class TestNormalizeEin < GLCommand::Callable
  requires string: String

  returns :ein

  def call
    context.ein = normalize(string)
  end

  def normalize(ein)
    return nil if ein.blank?

    ein_int = ein.gsub(/[^0-9]/, '')

    [ein_int[0..1], ein_int[2..]].join('-')
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

  chain TestNormalizeEin, CreateTestNpo

  returns :test_npo

  def call
    chain(string:)
  end
end

class ChainClass1 < GLCommand::Callable
  requires :obj
  returns :obj_1

  def call
    obj.one = '1'
    obj
  end

  def rollback
    obj.one = '1-rolled'
  end
end

class ChainClass2 < GLCommand::Callable
  requires :obj_1
  returns :obj_2

  def call
    obj_1.two = '2'
    obj_1
  end

  def rollback
    obj_1.two = '2-rolled'
  end
end

class ChainClass3 < GLCommand::Callable
  requires :obj_2
  allows fail_message: String
  returns :obj_3

  def call
    obj_2.three = '3'
    stop_and_fail!(fail_message) if fail_message.present?
    obj_2
  end

  def rollback
    obj_2.three = '3-rolled'
    context.obj_3 = obj_2
  end
end

class TestChainable < GLCommand::Chainable
  requires :obj
  allows :fail_message
  returns :obj_3

  chain ChainClass1, ChainClass2, ChainClass3
end

class TestScope < GLCommand::Callable
  requires :scope
  allows :should_fail
  returns :context_as_string

  def call
    raise 'test failure' if should_fail

    context.context_as_string = context.inspect
  end
end
