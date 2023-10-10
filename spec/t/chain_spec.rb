# frozen_string_literal: true

require 'spec_helper'

RSpec.describe T::Chain do
  describe 'A Chain class' do
    subject(:call) {test_class.call(foo: :bar) }

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
  end
end
