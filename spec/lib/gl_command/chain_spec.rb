# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/nonprofit_classes'

RSpec.describe GlCommand::Chain do
  describe 'CreateNormalizedNonprofit' do
    it 'has the commands' do
      expect(CreateNormalizedNonprofit.commands).to eq([NormalizeEin, CreateNonprofit])
    end

    describe 'call' do
      it 'calls' do
        result = CreateNormalizedNonprofit.call(ein: '810693451')
        pp "SPEC: #{result}"
        expect(result).to be_successful
        expect(result.error).to be_nil
        expect(result.nonprofit.ein).to eq '81-0693451'
        expect(result).not_to be_raise_errors
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
        %i[class_attrs ein ein= error error= fail! failure? nonprofit nonprofit= raise_errors? success? successful? to_h]
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
        let(:target) { '<GlCommand::Context \'CreateNormalizedNonprofit\' success: true, error: , data: {:ein=>nil, :nonprofit=>nil}>' }

        it 'renders inspect as expected' do
          expect(context.inspect).to eq target
        end
      end
    end
  end
end
