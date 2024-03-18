# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GlCommand::Context do
  describe 'fail' do
    let(:test_class) do
      Class.new(GlCommand::Base) do
        def call; end
      end
    end

    let(:context) { described_class.new(test_class) }

    it 'has no errors' do
      expect(context.errors).not_to be_any
    end

    it 'only adds an identical error once' do
      context.fail!('something')
      context.fail!('something')
      expect(context.errors).to eq(['something'])
    end
  end
end
