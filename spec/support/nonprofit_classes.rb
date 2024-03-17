# frozen_string_literal: true

class Nonprofit
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
      @id = Nonprofit.all.count + 1
    end
  end

  # REALLY hacky validate uniqueness
  validates_each :ein do |record, attr, value|
    existing_nonprofit = Nonprofit.all.find { |n| n.ein == value }
    record.errors.add attr, 'EIN already taken' if existing_nonprofit && existing_nonprofit&.id != record.id
  end

  def add_to_all_if_valid
    return if invalid?

    Nonprofit.all << self
  end
end

class NormalizeEin < GlCommand::Base
  returns :ein

  def call(ein:)
    context.ein = normalize(ein)
  end

  def normalize(ein)
    return nil if ein.blank?

    ein_int = ein.gsub(/[^0-9]/, '')

    [ein_int[0..1], ein_int[2..]].join('-')
  end
end

class CreateNonprofit < GlCommand::Base
  returns :nonprofit

  def call(ein:)
    context.nonprofit = Nonprofit.new(ein:)
  end
end

class CreateNormalizedNonprofit < GlCommand::Chain
  chain NormalizeEin, CreateNonprofit

  returns :nonprofit

  def call(ein:)
    chain(ein:)
  end
end
