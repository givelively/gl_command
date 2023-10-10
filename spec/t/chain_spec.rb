# frozen_string_literal: true

require 'spec_helper'

RSpec.describe T::Chain do
  describe 'A Chain class' do
    subject(:test_class) do
      success_link = Class.new do
        require 't/command'
        include T::Command

        def call
          # noop
        end
      end

      Class.new do
        require 't/command'
        include T::Command
        include T::Chain

        chain success_link
      end
    end

    it { is_expected.to respond_to(:call) }
    it { is_expected.to respond_to(:context) }

    it 'returns a T::Context' do
      expect(test_class.call).to be_a(T::Context)
    end

    it 'is successful' do
      expect(test_class.call).to be_successful
    end

    it 'is not a failure' do
      expect(test_class.call).not_to be_failure
    end
  end
end
