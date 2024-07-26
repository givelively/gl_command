# frozen_string_literal: true

require 'spec_helper'
require_relative '../../test_command_classes'

RSpec.describe GLCommand::ChainableContext do
  let(:context_instance_methods) do
    (ArrayAdd.build_context.methods & TestNormalizeEin.build_context.methods).sort -
      Object.instance_methods
  end
  let(:chain_context_instance_methods) do
    %i[chain_arguments_and_returns called called= initialize_chain_context] +
      context_instance_methods
  end

  describe 'ArrayChain' do
    let(:context) { ArrayChain.build_context }
    let(:target_called_arguments_and_returns) do
      %i[array item new_array popped_array popped_item revised_item]
    end
    let(:target_methods) do
      %i[array array= item item= new_array new_array= popped_array popped_array= revised_item
         revised_item=]
    end

    it 'is successful, chain? and does not raises_errors by default' do
      expect(context).not_to be_raise_error
      expect(context).to be_successful
      expect(context).to be_chain
      expect(context.class).to eq described_class
    end

    it 'has the instance method' do
      instance_methods = (context.methods - Object.instance_methods).sort
      expect(instance_methods).to match_array(target_methods + chain_context_instance_methods)
    end

    it 'has the chain_arguments_and_returns_h' do
      called_args_and_returns = (
        ArrayPop.arguments_and_returns +
        ArrayAdd.arguments_and_returns +
        ArrayChain.arguments_and_returns
      ).uniq.sort
      expect(called_args_and_returns).to eq target_called_arguments_and_returns
      expect(context.chain_arguments_and_returns.keys).to match_array(called_args_and_returns)
    end

    describe 'inspect' do
      let(:target) do
        '<GLCommand::ChainableContext error=nil, success=true, arguments={array: nil, item: nil}' \
          ', returns={new_array: nil, popped_array: nil, revised_item: nil}, called=[], ' \
          'class=ArrayChain>'
      end

      it 'inspect has called' do
        expect(ArrayChain.build_context.inspect).to eq target
      end
    end

    context 'with passed arguments and returns' do
      let(:passed_params) do
        { array: [1], new_array: [2], popped_array: [3], item: 4, revised_item: 5 }
      end
      let(:context) { ArrayChain.build_context(**passed_params) }
      let(:target_chain_hash) { passed_params.merge(popped_item: nil) }

      it 'sets the passed parameters' do
        expect(context.new_array).to eq([2])
        expect(context.popped_array).to eq([3])
        expect(context.revised_item).to eq(5)

        expect(context.to_h).to eq passed_params
        expect(context.chain_arguments_and_returns).to eq target_chain_hash
      end

      context 'with passed chain arguments and returns' do
        let(:passed_params) do
          { array: [1], new_array: [2], popped_array: [3], item: 4, revised_item: 5,
            popped_item: 3 }
        end
        let(:assignable_parameters) { ArrayChain.build_context.send(:assignable_parameters) }

        it 'sets the passed parameters' do
          expect(assignable_parameters).to match_array(passed_params.keys)
          expect(context.to_h).to eq passed_params.except(:popped_item)
          expect(context.chain_arguments_and_returns).to eq passed_params
        end
      end

      context 'with unknown argument' do
        let(:passed_params) { { something: 'fff' } }

        it 'raises' do
          expect do
            ArrayChain.build_context(something: 'test')
          end.to raise_error(ArgumentError)
        end

        context 'with skip_unknown_parameters' do
          let(:target_arguments_and_returns) { %i[array item new_array popped_array revised_item] }

          it "doesn't raise" do
            context = ArrayChain.build_context(skip_unknown_parameters: true, something: 'test')
            expect(context.to_h).to eq target_arguments_and_returns.zip([]).to_h
            target_chained = target_arguments_and_returns + [:popped_item]
            expect(context.chain_arguments_and_returns).to eq target_chained.zip([]).to_h
          end
        end
      end
    end
  end
end
