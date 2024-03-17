# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/nonprofit_classes'

RSpec.describe GlCommand::Chain do
  describe 'CreateNormalizedNonprofit' do
    it 'has the commands' do
      expect(CreateNormalizedNonprofit.commands).to eq([NormalizeEin, CreateNonprofit])
    end

    it 'is chain?' do
      expect(CreateNormalizedNonprofit).to be_chain
    end

    describe 'call' do
      it 'calls' do
        result = CreateNormalizedNonprofit.call(ein: '810693451')
        expect(result).to be_successful
        expect(result.error).to be_nil
        expect(result.nonprofit.ein).to eq '81-0693451'
        expect(result).not_to be_raise_errors
      end
    end

    describe 'call!' do
      it 'calls with bang' do
        result = CreateNormalizedNonprofit.call!(ein: '810693451')
        expect(result).to be_successful
        expect(result.error).to be_nil
        expect(result.nonprofit.ein).to eq '81-0693451'
        expect(result.called).to eq(CreateNormalizedNonprofit.commands)
        expect(result).to be_raise_errors
      end
    end

    describe 'returns' do
      it 'provides returns' do
        expect(CreateNormalizedNonprofit.returns).to eq([:nonprofit])
      end
    end

    describe 'arguments' do
      it 'provides arguments' do
        expect(CreateNormalizedNonprofit.arguments).to eq([:ein])
      end
    end

    describe 'context' do
      let(:context) { GlCommand::Context.new(CreateNormalizedNonprofit) }
      let(:target_methods) do
        %i[arguments assign_parameters called called= chain? ein ein= error error= fail! failure? klass nonprofit
           nonprofit= raise_errors? return_or_argument returns success? successful?]
      end

      it 'is successful and does not raises errors by default' do
        expect(context).not_to be_raise_error
        expect(context).to be_successful
      end

      it 'has the instance method' do
        context_instance_methods = (context.methods - Object.instance_methods).sort
        expect(context_instance_methods).to eq target_methods
      end

      context 'when passed raise_errors' do
        let(:context) { GlCommand::Context.new(CreateNormalizedNonprofit, raise_errors: true) }

        it 'is successful and raises errors' do
          expect(context).to be_raise_error
          expect(context).to be_successful
        end
      end

      describe 'inspect' do
        let(:target) do
          '<GlCommand::Context \'CreateNormalizedNonprofit\' success: true, error: nil, arguments: {:ein=>nil}, returns: {:nonprofit=>nil}, called: []>'
        end

        it 'renders inspect as expected' do
          expect(context.inspect).to eq target
        end
      end
    end

    describe 'rollback' do
      it 'calls rollback on each interactor when one fails'

      context 'with call!' do
        it 'calls rollback on each interactor when one fails'
      end
    end
  end

  describe "chain call that doesn't call chain" do
    let(:test_class) do
      Class.new(GlCommand::Chain) do
        def call; end
      end
    end

    it 'raises a legible error' do
      expect do
        test_class.call!
      end.to raise_error(/chain/i)
    end
  end

  context 'array classes' do
    class ArrayAddClass < GlCommand::Base
      returns :new_array

      def call(array:, item:)
        context.new_array = array.push(item).dup
        do_another_thing
      end

      def do_another_thing; end

      def rollback
        context.arguments[:array].pop
      end
    end

    class ChainClass < GlCommand::Chain
      chain ArrayAddClass

      def call(array:, item:)
        item += 5
        chain(array:, item:)
      end
    end

    let(:array) { [1, 2, 3, 4] }

    describe 'call' do
      it 'adds to the array' do
        result = ChainClass.call!(array:, item: 6)
        expect(result).to be_successful
        expect(array).to eq([1, 2, 3, 4, 11])
        expect(result.new_array).to eq array
      end
    end
  end
end
