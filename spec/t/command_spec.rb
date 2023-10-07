# frozen_string_literal: true

require 'spec_helper'

RSpec.describe T::Command do
  it 'has a version number' do
    expect(T::Command::VERSION).to be_a(String)
  end

  describe 'A Command class' do
    subject(:test_class) do
      Class.new do
        require 't/command'
        include T::Command

        def call
          context.foo = :bar
        end
      end
    end

    it { is_expected.to respond_to(:call) }
    it { is_expected.to respond_to(:context) }

    it 'returns a T::Context' do
      expect(test_class.call).to be_a(T::Context)
    end

    it 'is successful' do
      expect(test_class.call).to be_success
    end

    it 'is not a failure' do
      expect(test_class.call).not_to be_failure
    end
  end

  describe 'A failing Command class' do
    subject(:test_class) do
      Class.new do
        require 't/command'
        include T::Command

        def call
          non_existing_command
        end

        def rollback
          context.rolled_back = true
        end
      end
    end

    it 'returns a T::Context with a non-empty errors object' do
      expect(test_class.call.errors).not_to be_empty
    end

    it 'is not successful' do
      expect(test_class.call).not_to be_success
    end

    it 'is a failure' do
      expect(test_class.call).to be_failure
    end

    it 'calls `:rollback`' do
      expect(test_class.call(rolled_back: false).rolled_back).to be(true)
    end
  end
end
