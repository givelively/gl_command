# frozen_string_literal: true

require 'spec_helper'
require_relative '../../test_command_classes'

RSpec.describe GLCommand::Chainable do
  let(:context_instance_methods) do
    (ArrayAdd.build_context.methods & TestNormalizeEin.build_context.methods).sort -
      Object.instance_methods
  end
  let(:chain_context_instance_methods) do
    context_instance_methods + %i[chain_arguments_and_returns called called=
                                  initialize_chain_context]
  end

  describe 'CreateNormalizedTestNpo' do
    it 'has the commands' do
      expect(CreateNormalizedTestNpo.commands).to eq([TestNormalizeEin, CreateTestNpo])
    end

    it 'is chain?' do
      expect(CreateNormalizedTestNpo).to be_chain
    end

    describe 'call' do
      let(:result) { CreateNormalizedTestNpo.call(string: '810693451') }

      it 'calls' do
        expect(result).to be_successful
        expect(result.error).to be_nil
        expect(result.test_npo.ein).to eq '81-0693451'
        expect(result).not_to be_raise_errors
        expect(result.called).to eq([TestNormalizeEin, CreateTestNpo])
      end

      it 'updates the arguments' do
        expect(result.arguments.keys).to eq([:string])
        expect(result.returns.keys).to eq([:test_npo])
        # context.arguments are overridden in the chain, but this chain doesn't overwrite them
        expect(result.arguments).to eq({ string: '810693451' })
        # Verify chain information
        expect(result).to be_chain
        expect(result).not_to be_in_chain
      end
    end

    describe 'call!' do
      let(:result) { CreateNormalizedTestNpo.call!(string: '810693451') }

      it 'calls with bang' do
        expect(result).to be_successful
        expect(result.error).to be_nil
        expect(result.test_npo.ein).to eq '81-0693451'
        expect(result).to be_raise_errors
      end

      it 'updates the arguments' do
        expect(result.arguments.keys).to eq([:string])
        expect(result.returns.keys).to eq([:test_npo])
        expect(result.called).to eq(CreateNormalizedTestNpo.commands)
        expect(result.arguments).to eq({ string: '810693451' })
      end
    end

    describe 'returns' do
      it 'provides returns' do
        expect(CreateNormalizedTestNpo.returns).to eq([:test_npo])
      end
    end

    describe 'arguments' do
      it 'provides arguments' do
        expect(CreateNormalizedTestNpo.arguments).to eq([:string])
      end
    end

    describe 'context' do
      let(:context) { CreateNormalizedTestNpo.build_context }
      let(:target_methods) { %i[string string= test_npo test_npo=] }

      it 'is successful and does not raises errors by default' do
        expect(context).not_to be_raise_error
        expect(context).to be_successful
      end

      it 'has the instance method' do
        instance_methods = (context.methods - Object.instance_methods).sort
        expect(instance_methods).to match_array(target_methods + chain_context_instance_methods)
      end

      context 'when passed raise_errors' do
        let(:context) { GLCommand::Context.new(CreateNormalizedTestNpo, raise_errors: true) }

        it 'is successful and raises errors' do
          expect(context).to be_raise_error
          expect(context).to be_successful
        end
      end

      describe 'inspect' do
        let(:target) do
          '<GLCommand::ChainableContext error=nil, success=true, arguments={string: nil}' \
            ', returns={test_npo: nil}, called=[], class=CreateNormalizedTestNpo>'
        end

        it 'renders inspect as expected' do
          expect(context.inspect).to eq target
        end
      end
    end
  end

  describe 'without call defined' do
    let(:test_class) do
      Class.new(GLCommand::Chainable) do
        # Need to set the class name for validatable, or it raises: Class name cannot be blank.
        def self.name
          'TestChainableClass'
        end

        requires :array
        chain ArrayPop
      end
    end

    let(:array) { [12] }

    it 'succeeds' do
      result = test_class.call(array:)
      expect(result).to be_success
      expect(result).not_to be_no_notify
      expect(result.to_h).to eq({ array: [] })
      expect(array).to eq([])
    end

    context 'with error in chain validatable' do
      let(:array) { [12, nil, 12] }
      let(:target_error_message) do
        'Validation failed: Array Must be an array with no blank items!'
      end
      let(:result) { test_class.call(array:) }

      it 'fails' do
        expect(result).to be_a_failure
        expect(result.error.to_s).to eq target_error_message
        expect(result.full_error_message).to eq target_error_message
        expect(result.error.class).to eq(ActiveRecord::RecordInvalid)
        expect(array).to eq([12, nil, 12])
      end

      it 'fails without GLExceptionNotifier' do
        expect(GLExceptionNotifier).not_to receive(:call)
        expect(result).to be_a_failure
        expect(result).to be_no_notify
        expect(result.full_error_message).to eq target_error_message
        expect(result.error.class).to eq(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "chain call that doesn't call chain" do
    let(:test_class) do
      Class.new(GLCommand::Chainable) do
        def call; end
      end
    end

    it 'raises a legible error' do
      expect do
        test_class.call!
      end.to raise_error(/chain method/i)
    end

    describe 'call' do
      it 'fails, adds error' do
        result = test_class.call
        expect(result).to be_failure
        expect(result.error.to_s).to match(/chain method/i)
      end
    end
  end

  context 'with array_add_class chain' do
    let(:array) { [1, 2, 3, 4] }

    describe 'call' do
      let(:result) { ArrayChain.call!(array:, item: 6) }

      # rubocop:disable RSpec/MultipleExpectations
      it 'adds to the array' do
        expect(result).to be_successful
        expect(array).to eq([1, 2, 3, 4])
        expect(result.new_array).to eq array + [11]
        expect(result.revised_item).to eq 11
        expect(result.called).to eq([ArrayAdd, ArrayPop])
        expect(result.is_in_chain).to be_truthy
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    describe 'with validation failure' do
      let(:array) { ['a', ''] }
      let(:target_error_message) do
        'Validation failed: Array Must be an array with no blank items!'
      end
      let(:result) { ArrayChain.call(array:, item: 6) }

      # rubocop:disable RSpec/MultipleExpectations
      it 'adds an error' do
        expect(GLExceptionNotifier).not_to receive(:call)
        expect(result).not_to be_successful
        expect(result.error.to_s).to eq target_error_message
        expect(result.full_error_message).to eq target_error_message
        expect(result.error.class).to eq(ActiveRecord::RecordInvalid)
        expect(result.revised_item).to eq 8
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    describe 'rollback' do
      before do
        allow_any_instance_of(ArrayAdd).to receive(:do_another_thing) {
                                             raise 'Test Error'
                                           }
      end

      # rubocop:disable Metrics/AbcSize
      def failure_expectations(result)
        expect(result.error.to_s).to match(/Test Error/)
        expect(array).to eq([1, 2, 3, 4])
        expect(result.revised_item).to eq 8
        expect(result.new_array).to eq([1, 2, 3, 4, 11])
        expect(result.called).to eq([])
      end
      # rubocop:enable Metrics/AbcSize

      it 'command runs rollback if there is a failure' do
        result = ArrayChain.call(array:, item: 6)
        expect(result).not_to be_raise_errors
        failure_expectations(result)
      end

      context 'with call!' do
        it 'runs rollback on each command and raises' do
          expect do
            result = ArrayChain.call!(array:, item: 6)
            expect(result).to be_raise_errors
            failure_expectations(result)
          end.to raise_error(/Test Error/)
        end
      end
    end
  end

  describe 'validatable' do
    let(:test_class) do
      Class.new(GLCommand::Chainable) do
        requires array: Array, item: String

        chain ArrayAdd

        validates_with ArrayHasNoNilValidator

        # Need to set the class name for validatable, or it raises: Class name cannot be blank.
        def self.name
          'TestChainableValidatableClass'
        end
      end
    end

    let(:array) { [12] }

    it 'succeeds' do
      result = test_class.call(array:, item: '24')
      expect(result).to be_success
    end

    context 'with invalid argument' do
      let(:array) { [12, nil, 12] }
      let(:target_error_message) do
        'Validation failed: Array Must be an array with no blank items!'
      end

      it 'fails' do
        result = test_class.call(array:, item: '24')
        expect(result).to be_a_failure
        expect(result.errors.full_messages).to eq(['Array Must be an array with no blank items!'])
        expect(result.full_error_message).to eq target_error_message
        expect(result.error.class).to eq(ActiveRecord::RecordInvalid)
        expect(array).to eq([12, nil, 12])
      end
    end
  end

  describe 'chain_rollback' do
    let(:result) { TestChainable.call(obj:) }
    let(:special_obj) { Struct.new(:id, :one, :two, :three, keyword_init: true) }
    let(:obj) { special_obj.new(id: 42) }

    before { stub_const('SpecialObj', special_obj) }

    it 'instantiates each command with the arguments that it has as the time' do
      expect(result).to be_successful
      expect(result.called).to eq([ChainClass1, ChainClass2, ChainClass3])
      expect(result.obj_3).to eq obj
      expect(obj.three).to eq '3'
    end

    describe 'inspect' do
      let(:target) do
        '<GLCommand::ChainableContext error=nil, success=true, ' \
          'arguments={obj: #<SpecialObj id=42>, fail_message: nil}, ' \
          'returns={obj_3: #<SpecialObj id=42>}, called=[ChainClass1, ChainClass2, ChainClass3], ' \
          'class=TestChainable>'
      end

      it 'is target' do
        expect(result.inspect).to eq target
      end
    end

    context 'with failure' do
      let(:result) { TestChainable.call(obj:, fail_message: 'Failed') }
      let(:target) { { id: 42, one: '1-rolled', two: '2-rolled', three: '3-rolled' } }

      it 'calls rollback on itself after chain_rollback' do
        expect(GLExceptionNotifier).to receive(:call).once
        expect(result).to be_a_failure
        expect(result.called).to eq([ChainClass1, ChainClass2])
        expect(result.full_error_message).to eq 'Failed'
        expect(result.obj_3.to_h).to eq target
      end
    end
  end
end
