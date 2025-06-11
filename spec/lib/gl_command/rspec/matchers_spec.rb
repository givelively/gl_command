# frozen_string_literal: true

require 'spec_helper'

class MatcherTestCommand < GLCommand::Callable
  requires :required_arg, another_one: String
  allows :allowed_arg, and_another: Integer
  returns :returned_val

  def call; end
end

RSpec.describe GLCommand::Matchers, type: :callable do
  subject { MatcherTestCommand }

  describe 'interface matchers' do
    # Test `requires`
    it { is_expected.to require(:required_arg) }
    it { is_expected.to require(:another_one).being(String) }
    it { is_expected.not_to require(:allowed_arg) }
    it { is_expected.not_to require(:non_existent_arg) }
    it { is_expected.not_to require(:another_one).being(Integer) }

    # Test `allows`
    it { is_expected.to allow(:allowed_arg) }
    it { is_expected.to allow(:and_another).being(Integer) }
    it { is_expected.not_to allow(:required_arg) }
    it { is_expected.not_to allow(:non_existent_arg) }
    it { is_expected.not_to allow(:and_another).being(String) }

    # Test `returns`
    it { is_expected.to returns(:returned_val) }
    it { is_expected.not_to returns(:non_existent_val) }

    context 'when checking type on a `returns`' do
      let(:matcher) { returns(:returned_val).being(String) }

      it 'fails gracefully' do
        expect(matcher.matches?(command)).to be false
        expect(matcher.failure_message).to eq(
          'GLCommand::Callable does not store types for `returns`, so `.being()` cannot be used.'
        )
      end
    end
  end
end
