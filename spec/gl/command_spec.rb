# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GL::Command do
  it 'has a version number' do
    expect(GL::Command::VERSION).to be_a(String)
  end

  class Nonprofit
    include ActiveModel::Validations
    extend ActiveModel::Callbacks

    def self.all
      @nonprofits ||= []
    end

    attr_reader :ein, :name, :id

    validates_presence_of :ein, :name

    define_model_callbacks :initialize, only: :after
    after_initialize :add_to_all_if_valid

    def initialize(ein:, name:)
      run_callbacks :initialize do
        @ein = ein
        @name = name
        @id = Nonprofit.all.count + 1
      end
    end

    # REALLY hacky validate uniqueness
    validates_each :ein do |record, attr, value| 
      existing_nonprofit = Nonprofit.all.find { |n| n.ein == value }
      if existing_nonprofit && existing_nonprofit&.id != record.id
        record.errors.add attr, "EIN already taken"
      end
    end

    def add_to_all_if_valid
      # pp 'in add_to_all_if_valid'
      return if invalid?
      Nonprofit.all << self
    end
  end

  # class NormalizeEin
  #   include GL::Command

  #   returns :ein

  #   def call(ein:)
  #     context.ein = normalize(ein)
  #   end

  #   def normalize(ein)
  #     return nil if ein.blank?
  #     ein_int = ein.gsub(/[^0-9]/, '')

  #     [ein_int[0..1], ein_int[2..]].join("-")
  #   end
  # end


  # class CreateNormalizedNonprofit
  #   include GL::Command

  #   def call(ein:, name:)
  #     Nonprofit.new(ein:, name:)
  #   end
  # end

  # class CreateNonprofit
  #   include GL::Command
  #   include GL::Chain

  #   returns :nonprofit

  #   def call_chain(ein:, name:)
  #     NormalizeEin,
  #     CreateNormalizedNonprofit
  #   end
  # end

  describe 'Nonprofit initialize' do
    it 'is valid' do
      expect do
        nonprofit = Nonprofit.new(ein: '00-1111111', name: 'Test')
        expect(nonprofit).to be_valid
        expect(nonprofit.errors.count).to eq 0
      end.to change(Nonprofit.all, :count).by 1
    end

    context 'invalid' do
      it 'is invalid with missing ein' do
        expect do
          nonprofit = Nonprofit.new(ein: ' ', name: 'Test')
          expect(nonprofit).not_to be_valid
          expect(nonprofit.errors.count).to eq 1
          expect(nonprofit.errors.full_messages.to_s).to match(/ein.*blank/i)
        end.to change(Nonprofit.all, :count).by 0
      end

      it 'is invalid with missing name' do
        expect {
          nonprofit = Nonprofit.new(ein: '11-1111111', name: nil)
          expect(nonprofit.errors.count).to eq 1
          expect(nonprofit.errors.full_messages.to_s).to match(/name.*blank/i)
        }.to change(Nonprofit.all, :count).by 0
      end

      it 'is invalid with duplicate ein' do
        Nonprofit.new(ein: '00-1111111', name: 'Test')
        expect {
          nonprofit = Nonprofit.new(ein: '00-1111111', name: 'New Test')
          expect(nonprofit.errors.count).to eq 1
          expect(nonprofit.errors.full_messages.to_s).to match(/ein already taken/i)
        }.to change(Nonprofit.all, :count).by 0
      end
    end
  end

  # describe 'NormalizeEin' do
  #   let(:ein) { '81-0693451' }

  #   describe 'call argument errors' do
  #     it 'errors if called without keyword' do
  #       expect(NormalizeEin.call(ein)).to_raise(ArgumentError)
  #     end

  #     it 'errors if called with a different keyword' do
  #       expect
  #     end

  #     it 'returns the parameters' do
  #       # def call(something:, stuff: nil)
  #       # end
  #       # method(:call).parameters
  #     end
  #   end
  # end

    # context 'when entering happy path' do
    #   subject(:test_class) do
    #     Class.new(BaseCommand) do
    #       def call
    #         context.foo = :bar
    #       end
    #     end
    #   end

    #   it { is_expected.to respond_to(:call) }
    #   it { is_expected.to respond_to(:context) }

    #   it 'returns a GL::Context' do
    #     expect(test_class.call).to be_a(GL::Context)
    #   end

    #   it 'is successful' do
    #     expect(test_class.call).to be_successful
    #   end

    #   it 'is not a failure' do
    #     expect(test_class.call).not_to be_failure
    #   end
    # end

    # describe 'A failing Command class' do
    #   subject(:test_class) do
    #     Class.new(BaseCommand) do
    #       def call(at: )
    #         non_existing_command
    #       end

    #       def rollback
    #         context.rolled_back = true
    #       end
    #     end
    #   end

    #   it 'returns a GL::Context with a non-empty errors object' do
    #     expect(test_class.call.errors).not_to be_empty
    #   end

    #   it 'is not successful' do
    #     expect(test_class.call).not_to be_successful
    #   end

    #   it 'is a failure' do
    #     expect(test_class.call).to be_failure
    #   end

    #   it 'calls `:rollback`' do
    #     expect(test_class.call(rolled_back: false).rolled_back).to be(true)
    #   end
    # end

    # describe 'a Command class called with invalid parameters' do
    #   subject(:test_class) do
    #     Class.new(BaseCommand) do
    #       def call; end
    #     end
    #   end

    #   it 'fails with a readable exception' do
    #     expect { test_class.call(:not_a_hash) }.to raise_error(GL::NotAContextError)
    #   end
    # end

    # describe 'Delegation' do
    #   context 'when using :requires' do
    #     context 'without type specification' do
    #       subject(:test_class) do
    #         Class.new(BaseCommand) do
    #           requires :foo

    #           def call
    #             raise if foo.blank?
    #           end
    #         end
    #       end

    #       it 'delegates variable to the context' do
    #         expect(test_class.call(foo: :bar)).to be_successful
    #       end
    #     end

    #     context 'with type specification' do
    #       subject(:test_class) do
    #         Class.new(BaseCommand) do
    #           requires foo: String

    #           def call
    #             raise if foo.blank?
    #           end
    #         end
    #       end

    #       it 'delegates variable to the context' do
    #         expect(test_class.call(foo: 'a')).to be_successful
    #       end
    #     end
    #   end

    #   context 'when using :allows' do
    #     context 'without type specification' do
    #       subject(:test_class) do
    #         Class.new(BaseCommand) do
    #           allows :foo

    #           def call
    #             raise if foo.blank?
    #           end
    #         end
    #       end

    #       it 'delegates variable to the context' do
    #         expect(test_class.call(foo: :bar)).to be_successful
    #       end
    #     end

    #     context 'with type specification' do
    #       subject(:test_class) do
    #         Class.new(BaseCommand) do
    #           allows foo: String

    #           def call
    #             raise if foo.blank?
    #           end
    #         end
    #       end

    #       it 'delegates variable to the context' do
    #         expect(test_class.call(foo: 'a')).to be_successful
    #       end
    #     end
    #   end

    #   context 'when using :returns' do
    #     context 'without type specification' do
    #       subject(:test_class) do
    #         Class.new(BaseCommand) do
    #           returns :foo

    #           def call
    #             context.foo = :bar
    #             raise if foo.blank?
    #           end
    #         end
    #       end

    #       it 'delegates variable to the context' do
    #         expect(test_class.call).to be_successful
    #       end
    #     end

    #     context 'with type specification' do
    #       subject(:test_class) do
    #         Class.new(BaseCommand) do
    #           returns foo: String

    #           def call
    #             context.foo = 'a'
    #             raise if foo.blank?
    #           end
    #         end
    #       end

    #       it 'delegates variable to the context' do
    #         expect(test_class.call).to be_successful
    #       end
    #     end
    #   end
    # end
  # end
end
