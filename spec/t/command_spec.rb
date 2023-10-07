# frozen_string_literal: true

require 'spec_helper'

RSpec.describe T::Command do
  subject(:test_class) do
    Class.new do
      require 't/command'

      include T::Command
    end
  end

  it 'has a version number' do
    expect(T::Command::VERSION).to be_a(String)
  end

  describe 'A Command class' do
    it { is_expected.to respond_to(:call) }
    it { is_expected.to respond_to(:context) }
  end
end
