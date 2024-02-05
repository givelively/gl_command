# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GL::Command do
  describe 'hooks' do
    context 'with a before hook calling a method' do
      subject(:call) { test_class.call }

      let(:test_class) do
        Class.new do
          require 'gl/command'
          include GL::Command

          before :set_before_test

          def call
            context.before_ran = context.before_test == 1
          end

          private

          def set_before_test
            context.before_test = 1
          end
        end
      end

      it 'calls the before hook' do
        expect(call.before_ran).to be(true)
      end
    end

    context 'with a before hook calling a lamda' do
      subject(:call) { test_class.call }

      let(:test_class) do
        Class.new do
          require 'gl/command'
          include GL::Command

          before -> { context.before_test = 1 }

          def call
            context.before_ran = context.before_test == 1
          end
        end
      end

      it 'calls the before hook' do
        expect(call.before_ran).to be(true)
      end
    end

    context 'with an after hook calling a method' do
      subject(:call) { test_class.call }

      let(:test_class) do
        Class.new do
          require 'gl/command'
          include GL::Command

          after :set_after_test

          private

          def call
            # noop
          end

          def set_after_test
            context.after_test = 1
          end
        end
      end

      it 'calls the after hook' do
        expect(call.after_test).to eq(1)
      end
    end

    context 'with an after hook calling a lamda' do
      subject(:call) { test_class.call }

      let(:test_class) do
        Class.new do
          require 'gl/command'
          include GL::Command

          after -> { context.after_test = 1 }

          def call
            # noop
          end
        end
      end

      it 'calls the after hook' do
        expect(call.after_test).to eq(1)
      end
    end
  end
end
