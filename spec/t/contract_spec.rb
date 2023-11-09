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

        it 'fails if variable is given and type wrong' do
          expect(test_class.call(bar: 1)).to be_failure
        end

        it 'succeeds if variable is given and type correct' do
          expect(test_class.call(bar: 'a')).to be_success
        end
      end
    end

    context 'with allowed variable' do
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

        it 'fails if variable is given and type wrong' do
          expect(test_class.call(bar: 1)).to be_failure
        end

        it 'succeeds if variable is not given' do
          expect(test_class.call).to be_success
        end

        it 'succeeds if variable is given and type correct' do
          expect(test_class.call(bar: 'a')).to be_success
        end
      end
    end

    context 'when a return variable is specified' do
      context 'without type specification' do
        context 'when not setting the return variable' do
          let(:test_class) do
            Class.new(BaseContract) do
              returns :bar
            end
          end

          it 'fails if the variable is not given after call' do
            expect(test_class.call).to be_failure
          end
        end

        context 'when setting the return variable' do
          let(:test_class) do
            Class.new(BaseContract) do
              returns :bar

              def call
                context.bar = 'foo'
              end
            end
          end

          it 'succeeds if the variable is given after call' do
            expect(test_class.call).to be_success
          end
        end
      end

      context 'with type specification' do
        let(:test_class) do
          Class.new(BaseContract) do
            returns bar: String

            def call
              context.bar = context.input
            end
          end
        end

        it 'fails if the variable is not given after call' do
          expect(test_class.call).to be_failure
        end

        it 'fails if variable is given after call and type wrong' do
          expect(test_class.call(input: 1)).to be_failure
        end

        it 'succeeds if variable is given after call and type correct' do
          expect(test_class.call(input: 'a')).to be_success
        end
      end
    end
  end
end
