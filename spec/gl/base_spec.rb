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
          end.not_to change(Nonprofit.all, :count)
        end

        it 'is invalid with duplicate ein' do
          Nonprofit.new(ein: '00-1111111')
          expect do
            nonprofit = Nonprofit.new(ein: '00-1111111')
            expect(nonprofit.errors.count).to eq 1
            expect(nonprofit.errors.full_messages.to_s).to match(/ein already taken/i)
          end.not_to change(Nonprofit.all, :count)
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

      [ein_int[0..1], ein_int[2..]].join('-')
    end
  end

  describe 'NormalizeEin' do
    let(:ein) { '81-0693451' }

    describe 'returns' do
      it 'provides returns' do
        expect(NormalizeEin.returns).to eq([:ein])
      end
    end

    describe 'arguments' do
      it 'provides returns' do
        expect(NormalizeEin.arguments_hash).to eq({required: [:ein], optional: []})
        expect(NormalizeEin.arguments).to eq([:ein])
      end
    end

    describe 'call' do
      it 'returns the expected result' do
        result = NormalizeEin.call(ein: '001111111')
        expect(result).to be_successful
        expect(result.error).to be_nil
        expect(result.ein).to eq '00-1111111'
        expect(result.raise_errors?).to be_falsey
      end
    end

    describe 'ArgumentError' do
      it "doesn't raise" do
        result = NormalizeEin.call(not_ein: ein)
        expect(result).not_to be_successful
        expect(result.error.class).to match(ArgumentError)
      end

      context 'with raise_errors: true' do
        it 'errors if called without keyword' do
          expect { NormalizeEin.call(ein, raise_errors: true) }.to raise_error(ArgumentError)
        end

        it 'errors if called with a different keyword' do
          expect { NormalizeEin.call(not_ein: ein, raise_errors: true) }.to raise_error(ArgumentError)
        end
      end

      context 'with call!' do
        it 'errors if called without keyword' do
          expect { NormalizeEin.call!(ein) }.to raise_error(ArgumentError)
        end

        it 'errors if called with a different keyword' do
          expect { NormalizeEin.call!(not_ein: ein) }.to raise_error(ArgumentError)
        end
      end
    end

    describe 'context' do
      let(:context) { GL::Context.new(NormalizeEin) }

      it 'is successful and does not raises errors by default' do
        expect(context).not_to be_raise_error
        expect(context).to be_successful
      end

      it 'has the return method' do
        context_instance_methods = (context.methods - Object.instance_methods).sort
        expect(context_instance_methods).to eq(%i[class_attrs ein ein= error error= fail! failure? raise_errors? success?
                                                  successful? to_h])
      end

      context 'passed raise_errors' do
        let(:context) { GL::Context.new(NormalizeEin, raise_errors: true) }

        it 'is successful and raises errors' do
          expect(context).to be_raise_error
          expect(context).to be_successful
        end
      end

      describe 'inspect' do
        let(:target) { '<GL::Context \'NormalizeEin\' success: true, error: , data: {:ein=>nil}>' }

        it 'renders inspect as expected' do
          expect(context.inspect).to eq target
        end
      end
    end
  end

  describe 'command with positional_parameter' do
    class TestCommand < GL::Command
      def call(something, another_thing:); end
    end

    it 'raises a legible error' do
      expect do
        TestCommand.call('fff', another_thing: 'herere')
      end.to raise_error(/only.*keyword/i)
    end
  end

  class CreateNormalizedNonprofit < GL::Command
    def call(ein:, name:)
      Nonprofit.new(ein:, name:)
    end

    def rollback
      # do something!
    end
  end

  describe 'rollback' do
    it 'runs a rollback'
  end

  class CreateNonprofit < GL::CommandChain
    def call_chain(ein:)
      [NormalizeEin,
       CreateNormalizedNonprofit]
    end
  end

  describe 'CreateNonprofit' do
    it 'chains'
  end
end
