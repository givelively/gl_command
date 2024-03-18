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
      let(:result) { CreateNormalizedNonprofit.call(ein: '810693451') }

      it 'calls' do
        expect(result).to be_successful
        expect(result.errors).to eq([])
        expect(result.nonprofit.ein).to eq '81-0693451'
        expect(result).not_to be_raise_errors
        expect(result.called).to eq([NormalizeEin, CreateNonprofit])
      end

      it 'updates the arguments' do
        expect(result.arguments.keys).to eq([:ein])
        expect(result.returns.keys).to eq([:nonprofit])
        # context.arguments are updated in the chain, from NormalizeEin
        expect(result.arguments).to eq({ ein: '81-0693451' })
      end
    end

    describe 'call!' do
      let(:result) { CreateNormalizedNonprofit.call!(ein: '810693451') }

      it 'calls with bang' do
        expect(result).to be_successful
        expect(result.errors).to eq([])
        expect(result.nonprofit.ein).to eq '81-0693451'
        expect(result).to be_raise_errors
      end

      it 'updates the arguments' do
        expect(result.arguments.keys).to eq([:ein])
        expect(result.returns.keys).to eq([:nonprofit])
        expect(result.called).to eq(CreateNormalizedNonprofit.commands)
        # context.arguments are updated in the chain, from NormalizeEin
        expect(result.arguments).to eq({ ein: '81-0693451' })
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
        %i[arguments assign_parameters called called= chain? ein ein= errors errors= fail! failure? klass nonprofit
           nonprofit= raise_errors? returns success? successful? to_h]
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
          '<GlCommand::Context \'CreateNormalizedNonprofit\' success: true, ' \
            'errors: [], arguments: {:ein=>nil}, returns: {:nonprofit=>nil}, called: []>'
        end

        it 'renders inspect as expected' do
          expect(context.inspect).to eq target
        end
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

  context 'with array_add_class chain' do
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
      chain ArrayAddClass, ArrayAddClass

      returns :revised_item

      def call(array:, item:)
        context.revised_item = item + 5
        chain(array:, item: context.revised_item)
      end

      def rollback
        context.revised_item = context.arguments[:item] - 3
      end
    end

    let(:array) { [1, 2, 3, 4] }

    describe 'call' do
      let(:result) { ChainClass.call(array:, item: 6) }

      it 'adds to the array' do
        expect(result).to be_successful
        expect(array).to eq([1, 2, 3, 4, 11, 11])
        expect(result.new_array).to eq array
        expect(result.revised_item).to eq 11
        expect(result.called).to eq([ArrayAddClass, ArrayAddClass])
      end
    end

    describe 'rollback' do
      before { allow_any_instance_of(ArrayAddClass).to receive(:do_another_thing) { raise 'Test Error' } }

      def failure_expectations(result)
        expect(result.errors.to_s).to match(/Test Error/)
        expect(array).to eq([1, 2, 3, 4])
        expect(result.revised_item).to eq 8
        expect(result.new_array).to eq([1, 2, 3, 4, 11])
        expect(result.called).to eq([])
      end

      it 'command runs rollback if there is a failure' do
        result = ChainClass.call(array:, item: 6)
        expect(result).not_to be_raise_errors
        failure_expectations(result)
      end

      context 'call!' do
        it 'runs rollback on each command and raises' do
          expect do
            result = ChainClass.call!(array:, item: 6)
            expect(result).to be_raise_errors
            failure_expectations(result)
          end.to raise_error(/Test Error/)
        end
      end
    end
  end

  describe 'chain_rollback' do
    it 'instantiates each command with the arguments that it has as the time'

    it 'calls rollback on itself after chain_rollback'
  end
end
