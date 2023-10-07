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

    it 'returns a context' do
      expect(test_class.call).to be_a(T::Context)
    end
  end
end
