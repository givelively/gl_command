# frozen_string_literal: true

require 'spec_helper'

RSpec.describe T::Contract do
  describe 'A Contract class' do
    before do
      base_contract = Class.new(Object) do
        require 't/command'
        include T::Command
        include T::Contract

        def call; end
      end
      stub_const('BaseContract', base_contract)
    end

    context 'with a required variable' do
      context 'without type specification' do
        let(:test_class) do
          Class.new(BaseContract) do
            requires :bar
          end
        end

        it 'fails if variable is not given' do
          expect(test_class.call).to be_failure
        end

        it 'succeeds if variable is given' do
          expect(test_class.call(bar: true)).to be_success
        end
      end

      context 'with type specification' do
        let(:test_class) do
          Class.new(BaseContract) do
            requires bar: String
          end
        end

        it 'fails if variable is not given' do
          expect(test_class.call).to be_failure
        end

        it 'succeeds if variable is given and type correct' do
          expect(test_class.call(bar: 'a')).to be_success
        end

        it 'fails if variable is given and type wrong' do
          expect(test_class.call(bar: 1)).to be_failure
        end
      end
    end

    context 'with allowed variables' do
      context 'without type specification' do
        let(:test_class) do
          Class.new(BaseContract) do
            allows :bar
          end
        end

        it 'succeeds if the allowed variable is not given' do
          expect(test_class.call).to be_success
        end

        it 'succeeds if the allowed variable is given' do
          expect(test_class.call(bar: true)).to be_success
        end
      end

      context 'with type specification' do
        let(:test_class) do
          Class.new(BaseContract) do
            allows bar: String
          end
        end

        it 'succeeds if variable is not given' do
          expect(test_class.call).to be_success
        end

        it 'succeeds if variable is given and type correct' do
          expect(test_class.call(bar: 'a')).to be_success
        end

        it 'fails if variable is given and type wrong' do
          expect(test_class.call(bar: 1)).to be_failure
        end
      end
    end
  end
end
