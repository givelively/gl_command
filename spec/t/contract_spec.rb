# frozen_string_literal: true

require 'spec_helper'

RSpec.describe T::Contract do
  describe 'A Contract class' do
    let(:test_class) do
      Class.new(Object) do
        require 't/command'
        include T::Command
        include T::Contract

        def self.model_name
          ActiveModel::Name.new(self, nil, 'temp')
        end

        requires :bar
        allows foo: String
        # returns :baz

        def call
          context.baz = context.bar
        end
      end
    end

    context 'with required variables' do
      it 'fails if a required variable is not given' do
        expect(test_class.call).to be_failure
      end

      it 'succeeds if the required variable is given' do
        expect(test_class.call(bar: true)).to be_success
      end
    end

    context 'with allowed variables' do
      it 'succeeds if the allowed variable is not given' do
        expect(test_class.call(bar: true)).to be_success
      end

      it 'succeeds if the allowed variable is given' do
        expect(test_class.call(bar: true, foo: 'a')).to be_success
      end

      it 'fails if the allowed variable is of the wrong type' do
        expect(test_class.call(bar: true, foo: 1)).to be_failure
      end
    end
  end
end
