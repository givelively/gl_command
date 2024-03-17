# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/nonprofit_classes'

# NOTE: Nonprofit isn't actually a GlCommand, but these tests are useful for verifying setup
RSpec.describe Nonprofit do
  describe 'initialize' do
    let(:nonprofit) { described_class.new(ein: '00-1111111') }

    it 'is valid' do
      expect do
        expect(nonprofit).to be_valid
        expect(nonprofit.errors.count).to eq 0
      end.to change(described_class.all, :count).by 1
    end

    context 'with missing ein' do
      let(:nonprofit) { described_class.new(ein: ' ') }

      it 'is invalid with missing ein' do
        expect do
          expect(nonprofit).not_to be_valid
          expect(nonprofit.errors.count).to eq 1
          expect(nonprofit.errors.full_messages.to_s).to match(/ein.*blank/i)
        end.not_to change(described_class.all, :count)
      end
    end

    context 'with duplicate ein' do
      before { described_class.new(ein: '00-1111111') }

      it 'is invalid with duplicate ein' do
        expect do
          nonprofit = described_class.new(ein: '00-1111111')
          expect(nonprofit.errors.count).to eq 1
          expect(nonprofit.errors.full_messages.to_s).to match(/ein already taken/i)
        end.not_to change(described_class.all, :count)
      end
    end
  end
end
