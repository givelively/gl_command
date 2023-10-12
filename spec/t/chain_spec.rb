# frozen_string_literal: true

require 'spec_helper'

RSpec.describe T::Chain do
  describe 'A Chain class' do
    subject(:call) { test_class.call(foo: :bar) }

    let(:test_class) do
      success_link = Class.new do
        require 't/command'
        include T::Command

        def call
          context.success_link_called = true
        end
      end

      Class.new do
        require 't/command'
        include T::Command
        include T::Chain

        chain success_link
      end
    end

    it { is_expected.to be_a(T::Context) }
    it { is_expected.to be_successful }
    it { is_expected.not_to be_failure }

    it 'carries over the context' do
      expect(call.foo).to eq(:bar)
    end

    it 'carries over the context of the commands' do
      expect(call.success_link_called).to be(true)
    end

    context 'with a failing command' do
      let(:test_class) do
        first_link = Class.new do
          require 't/command'
          include T::Command

          def call
            context.first_link_called = true
          end

          def rollback
            context.first_link_rolled_back = true
          end
        end

        second_link = Class.new do
          require 't/command'
          include T::Command

          def call
            context.second_link_called = true
            raise 'oh noes'
          end

          def rollback
            context.second_link_rolled_back = true
          end
        end

        third_link = Class.new do
          require 't/command'
          include T::Command

          def call
            context.third_link_called = true
          end

          def rollback
            context.third_link_rolled_back = true
          end
        end

        Class.new do
          require 't/command'
          include T::Command
          include T::Chain

          chain first_link
          chain second_link
          chain third_link
        end
      end

      it 'calls the first command' do
        expect(call.first_link_called).to be(true)
      end

      it 'calls the second command' do
        expect(call.second_link_called).to be(true)
      end

      it 'does not call the third command' do
        expect(call.third_link_called).to be_nil
      end

      it 'calls rollback on the second command' do
        expect(call.second_link_rolled_back).to be(true)
      end

      it 'calls rollback on the first command' do
        expect(call.first_link_rolled_back).to be(true)
      end

      it 'does not call rollback on the third command' do
        expect(call.third_link_rolled_back).to be_nil
      end
    end
  end
end
