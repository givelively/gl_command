# frozen_string_literal: true

RSpec.describe T::Command do
  it 'has a version number' do
    expect(T::Command::VERSION).to be_a(String)
  end

  describe 'A Command class' do
    it 'responds to `.call`' do
      expect(described_class).to respond_to(:call)
    end
  end
end
