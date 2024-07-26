require 'spec_helper'
require_relative '../../test_command_classes'

RSpec.describe GLCommand::ContextInspect do
  describe 'context method_missing (loop)' do
    let(:test_class) do
      Class.new(GLCommand::Callable) do
        allows :full_error_message_str
        def call
          context.some_unknown_method
        end
      end
    end
    let(:result) { test_class.call }

    it "doesn't create a crazy self referential full_error_message" do
      # NOTE: Without $ERROR_INFO matching, this error length is 233632
      expect(result).to be_a_failure
      expect(result.full_error_message.length).to be < 300
      expect(result.inspect.length).to be < 500
      expect(result.error.class).to eq NoMethodError
    end
  end

  describe 'TestScope' do
    subject(:call) { TestScope.call(scope:, should_fail:) }

    let(:nonprofit) { create(:nonprofit) }
    let(:scope) { nonprofit.line_items }

    let(:expected_context_string) do
      '<GLCommand::Context error=nil, success=true, ' \
        'arguments={scope: #<ActiveRecord::Associations::CollectionProxy ' \
        'count=0, sql="SELECT "line_items".* FROM "line_items" WHERE ' \
        "\"line_items\".\"nonprofit_id\" = '#{nonprofit.id}'\">, " \
        "should_fail: #{should_fail}}, returns={context_as_string: nil}, class=TestScope>"
    end

    context 'when it succeeds' do
      let(:should_fail) { false }

      it 'returns the correct data' do
        expect(GLExceptionNotifier).not_to receive(:call)
        result = call
        expect(result).to be_success
        expect(result.context_as_string).to eq(expected_context_string)
      end
    end

    context 'when it fails' do
      let(:should_fail) { true }

      it 'sends the correct data to GLExceptionNotifier' do
        expect(GLExceptionNotifier).to(
          receive(:breadcrumbs).once.with(
            data: { context: expected_context_string },
            message: 'TestScope'
          )
        )
        expect(GLExceptionNotifier).to receive(:call).once
        result = call
        expect(result).not_to be_success
      end
    end
  end
end
