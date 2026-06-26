# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GLCommand::Matchers, type: :command do # rubocop:disable RSpec/FilePath, RSpec/SpecFilePathFormat
  subject(:command) { MatcherTestCommand }

  describe 'interface matchers' do
    # Test `requires`
    it { is_expected.to require(:required_arg) }
    it { is_expected.to require(:another_one).being(String) }
    it { is_expected.not_to require(:allowed_arg) }
    it { is_expected.not_to require(:non_existent_arg) }
    it { is_expected.not_to require(:another_one).being(Integer) }

    context 'when checking `not_to require`' do
      let(:matcher) { require(:required_arg) }

      it 'has the correct failure message' do
        expect(matcher.matches?(command)).to be true # so that not_to fails
        expect(matcher.failure_message_when_negated).to eq(
          'Expected MatcherTestCommand not to require `required_arg`'
        )
      end

      context 'with type' do
        let(:matcher) { require(:another_one).being(String) }

        it 'has the correct failure message' do
          expect(matcher.matches?(command)).to be true # so that not_to fails
          expect(matcher.failure_message_when_negated).to eq(
            'Expected MatcherTestCommand not to require `another_one` of type `String`'
          )
        end
      end
    end

    # Test `allows`
    it { is_expected.to allow(:allowed_arg) }
    it { is_expected.to allow(:and_another).being(Integer) }
    it { is_expected.not_to allow(:required_arg) }
    it { is_expected.not_to allow(:non_existent_arg) }
    it { is_expected.not_to allow(:and_another).being(String) }

    context 'when checking `not_to allow`' do
      let(:matcher) { allow(:allowed_arg) }

      it 'has the correct failure message' do
        expect(matcher.matches?(command)).to be true # so that not_to fails
        expect(matcher.failure_message_when_negated).to eq(
          'Expected MatcherTestCommand not to allow `allowed_arg`'
        )
      end

      context 'with type' do
        let(:matcher) { allow(:and_another).being(Integer) }

        it 'has the correct failure message' do
          expect(matcher.matches?(command)).to be true # so that not_to fails
          expect(matcher.failure_message_when_negated).to eq(
            'Expected MatcherTestCommand not to allow `and_another` of type `Integer`'
          )
        end
      end
    end

    # Test `returns`
    it { is_expected.to returns(:returned_val) }
    it { is_expected.not_to returns(:non_existent_val) }

    context 'when checking `not_to returns`' do
      let(:matcher) { returns(:returned_val) }

      it 'has the correct failure message' do
        expect(matcher.matches?(command)).to be true # so that not_to fails
        expect(matcher.failure_message_when_negated).to eq(
          'Expected MatcherTestCommand not to return `returned_val`'
        )
      end
    end

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
