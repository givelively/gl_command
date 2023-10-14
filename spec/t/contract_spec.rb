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
        # allows :foo
        # returns :baz

        def call
          context.baz = context.bar
        end
      end
    end

    it 'fails if a requirement is not met' do
      expect(test_class.call).to be_failure
    end

    it 'succeeds if the requirement is met' do
      expect(test_class.call(bar: true)).to be_success
    end
  end
end
