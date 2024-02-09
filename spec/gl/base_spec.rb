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
      if existing_nonprofit && existing_nonprofit&.id != record.id
        record.errors.add attr, "EIN already taken"
      end
    end

    def add_to_all_if_valid
      return if invalid?
      Nonprofit.all << self
    end
  end

  describe 'Nonprofit' do
    describe 'initialize' do
      it 'is valid' do
        expect do
          nonprofit = Nonprofit.new(ein: '00-1111111')
          expect(nonprofit).to be_valid
          expect(nonprofit.errors.count).to eq 0
        end.to change(Nonprofit.all, :count).by 1
      end

      context 'invalid' do
        it 'is invalid with missing ein' do
          expect do
            nonprofit = Nonprofit.new(ein: ' ')
            expect(nonprofit).not_to be_valid
            expect(nonprofit.errors.count).to eq 1
            expect(nonprofit.errors.full_messages.to_s).to match(/ein.*blank/i)
          end.to change(Nonprofit.all, :count).by 0
        end

        it 'is invalid with duplicate ein' do
          Nonprofit.new(ein: '00-1111111')
          expect {
            nonprofit = Nonprofit.new(ein: '00-1111111')
            expect(nonprofit.errors.count).to eq 1
            expect(nonprofit.errors.full_messages.to_s).to match(/ein already taken/i)
          }.to change(Nonprofit.all, :count).by 0
        end
      end
    end
  end

  class NormalizeEin < GL::Command
    returns :ein

    def call(ein:)
      context.ein = normalize(ein)
    end

    def normalize(ein)
      return nil if ein.blank?
      ein_int = ein.gsub(/[^0-9]/, '')

      [ein_int[0..1], ein_int[2..]].join("-")
    end
  end

  describe 'NormalizeEin' do
    let(:ein) { '81-0693451' }

    describe 'attributes' do
      it 'provides required parameters' do
        expect(NormalizeEin.arguments).to eq({required: [:ein]})
      end

      it 'provides returns' do
        expect(NormalizeEin.returns).to eq([:ein])
      end
    end

    describe 'ArgumentError' do
      it 'errors if called without keyword' do
        expect { NormalizeEin.call(ein) }.to raise_error(ArgumentError)
      end

      it 'errors if called with a different keyword' do
        expect { NormalizeEin.call(not_ein: ein) }.to raise_error(ArgumentError)
      end

      context 'with do_not_raise: true' do
        it 'it still raises (because this is a structural issue)' do
          expect do
            NormalizeEin.call(not_ein: ein, do_not_raise: true)
          end.to raise_error(ArgumentError)
        end
      end
    end
  end

  # describe 'positional_parameter' do
  #   class TestCommand < GL::Command
  #     def call(something, another_thing:)
  #     end
  #   end
  #   it 'raises with a legible error' do
  #     expect do
  #       TestCommand.call('fff', another_thing: "herere")
  #     end.to raise_error(/TestCommand.*only.*keyword/i)
  #   end
  # end

  # describe 'invalid parameters' do
  #   class BadCommand < GL::Command
  #     def call(ein)
  #     end
  #   end

  #   it 'is invalid' do
  #     Not sure how to write this test...
  #   end
  # end


  # class CreateNormalizedNonprofit < GL::Command
  #   include GL::Command

  #   def call(ein:, name:)
  #     Nonprofit.new(ein:, name:)
  #   end
  #   def rollback
  #     do something!
  #   end
  # end

  # class CreateNonprofit < GL::Command
  #   include GL::Command
  #   include GL::Chain

  #   returns :nonprofit

  #   def call_chain(ein:)
  #     NormalizeEin,
  #     CreateNormalizedNonprofit
  #   end
  # end



  # ----------------------------------------


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
