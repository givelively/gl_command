# frozen_string_literal: true

require 'spec_helper'
require_relative '../../test_command_classes'

RSpec.describe GLCommand::Context do
  # rubocop:disable RSpec/MultipleExpectations
  let(:context_instance_methods) do
    %i[arguments assign_callable assign_parameters chain? error error= errors failure?
       full_error_message full_error_message= klass no_notifiable_error_to_raise
       no_notify? opts_hash raise_errors? returns success? successful? to_h]
  end

  let(:test_class) do
    Class.new(GLCommand::Callable) do
      def call; end
    end
  end

  let(:context) { described_class.new(test_class) }

  describe 'arguments and returns' do
    it 'has arguments and returns' do
      expect(context.send(:arguments)).to eq({})
      expect(context.returns).to eq({})
      expect(context.to_h).to eq({})
      expect(context.chain?).to be_falsey
      expect(context.in_chain?).to be_falsey
    end

    it 'only has the base methods' do
      instance_methods = (context.methods - Object.instance_methods).sort
      # sanity check that the context_instance_methods are correct
      common_methods =
        (test_class.build_context.methods & TestNormalizeEin.build_context.methods).sort
      expect(context_instance_methods).to eq(common_methods - Object.instance_methods)
      expect(instance_methods).to match_array(context_instance_methods)
    end
  end

  describe 'inspect' do
    let(:target) do
      '<GLCommand::Context error=nil, success=true, ' \
        "arguments={}, returns={}, class=#{test_class}>"
    end

    it 'renders inspect as expected' do
      expect(test_class.build_context.class).to eq described_class
      expect(test_class.build_context.inspect).to eq target
    end
  end

  describe 'error=' do
    let(:assigned_error) { nil }

    before { context.error = assigned_error }

    # NOTE: This might be surprising! If you ever assign error, it makes the context a failure
    # (even if the error is nil)
    it 'is failure' do
      expect(context).not_to be_successful
      expect(context.error.class).to eq GLCommand::StopAndFail
      expect(context.full_error_message).to eq 'GLCommand::StopAndFail'
    end

    context 'with blank error' do
      let(:assigned_error) { ' ' }

      it 'has a blank error message' do
        expect(context).to be_failure
        expect(context.error.class).to eq GLCommand::StopAndFail
        expect(context.full_error_message).to eq ' '
      end
    end

    context 'when there are validation errors' do
      let(:context) do
        result = test_class.call
        result.errors.add(:base, 'A validation error')
        result
      end

      it 'error is ActiveRecord::RecordInvalid' do
        expect(context).to be_failure
        expect(context.error.class).to eq ActiveRecord::RecordInvalid
        expect(context.full_error_message).to eq 'Validation failed: A validation error'
      end
    end

    context 'with an error' do
      let(:assigned_error) { ActiveRecord::RecordNotFound }

      it 'assigns the error' do
        expect(context).to be_failure
        expect(context.error.class).to eq ActiveRecord::RecordNotFound
        expect(context.full_error_message).to eq 'ActiveRecord::RecordNotFound'
      end
    end

    context 'with an error with a message' do
      let(:assigned_error) { ActiveRecord::RecordNotFound.new('An error message') }

      it 'assigns the error' do
        expect(context).to be_failure
        expect(context.error.class).to eq ActiveRecord::RecordNotFound
        expect(context.full_error_message).to eq 'An error message'
      end
    end
  end

  context 'when callable class has args and returns' do
    let(:test_class) do
      Class.new(GLCommand::Callable) do
        requires :something

        allows :extra

        returns :new_thing, :extra

        def call; end
      end
    end

    let(:target_methods) { %i[something something= new_thing new_thing= extra extra=] }

    describe 'arguments and returns' do
      let(:context) { described_class.new(test_class) }

      it 'has arguments and returns' do
        expect(context.send(:arguments)).to eq({ something: nil, extra: nil })
        expect(context.returns).to eq({ new_thing: nil, extra: nil })
        expect(context.to_h).to eq({ something: nil, new_thing: nil, extra: nil })
      end

      it 'has the arguments and returns' do
        instance_methods = (context.methods - Object.instance_methods).sort
        # sanity check that the context_instance_methods are correct
        common_methods =
          (test_class.build_context.methods & GLCommand::Callable.build_context.methods).sort
        expect(context_instance_methods).to eq(common_methods - Object.instance_methods)
        expect(instance_methods).to match_array(target_methods + context_instance_methods)
      end
    end

    describe 'inspect' do
      let(:target) do
        '<GLCommand::Context error=nil, success=true, ' \
          'arguments={something: nil, extra: nil}, ' \
          "returns={new_thing: nil, extra: nil}, class=#{test_class}>"
      end

      it 'renders inspect as expected' do
        expect(test_class.build_context.class).to eq described_class
        expect(test_class.build_context.inspect).to eq target
      end

      describe 'with arguments and returns objects with ids' do
        let(:something) do
          something = Struct.new('Something', :id, :foo, :bar, keyword_init: true)
          something.new(id: 42, foo: 'something', bar: 'else')
        end
        let(:new_thing) do
          user_or_whatever = Struct.new('UserOrWhatever', :uuid, :email, :name,
                                        :created_at, :updated_at, keyword_init: true)
          user_or_whatever.new(uuid: 'ff9c64dd-9a0d-4ce4-a72f-b54037bcc28e',
                               email: 'f@f.f', name: 'g', created_at: Time.now,
                               updated_at: Time.now)
        end
        let(:context) { test_class.build_context(something:, new_thing:) }
        let(:target) do
          '<GLCommand::Context error=nil, success=true, ' \
            'arguments={something: #<Struct::Something id=42>, extra: nil}, ' \
            'returns={new_thing: #<Struct::UserOrWhatever ' \
            "uuid=\"ff9c64dd-9a0d-4ce4-a72f-b54037bcc28e\">, extra: nil}, class=#{test_class}>"
        end

        it 'renders just the ID' do
          expect(context.inspect).to eq target
        end
      end
    end
  end

  describe 'failure?' do
    let(:full_error_message_str) { 'something' }
    let(:set_no_notify) { false }
    let(:context) { test_class.call(full_error_message_str:, set_no_notify:) }

    context 'with errors' do
      let(:test_class) do
        Class.new(GLCommand::Callable) do
          allows :full_error_message_str, :set_no_notify
          def call
            context.instance_variable_set(:@no_notify, true) if set_no_notify

            context.errors.add(:base, full_error_message_str)
          end
        end
      end

      it 'is failure' do
        expect(context.errors).to be_present
        expect(context).to be_failure
        expect(context).not_to be_no_notify
        expect(context).not_to be_raise_errors
        expect(context.error.class).to eq ActiveRecord::RecordInvalid
        expect(context.full_error_message).to eq 'Validation failed: something'
      end

      context 'with raise_errors: true' do
        it 'does not call GLExceptionNotifier' do
          expect(GLExceptionNotifier).not_to receive(:call)

          expect do
            test_class.call!(full_error_message_str:)
          end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: something')
        end

        it 'raises error without cause' do
          test_class.call!(full_error_message_str:, set_no_notify:)
        rescue StandardError => e
          expect(e.class).to eq ActiveRecord::RecordInvalid
          expect(e.to_s).to eq 'Validation failed: something'
          expect(e.cause).to be_blank
        end
      end

      context 'with no_notify' do
        let(:set_no_notify) { true }

        it 'is no_notify' do
          expect(context).to be_failure
          expect(context).to be_no_notify
          expect(context).not_to be_raise_errors
          expect(context.error.class).to eq ActiveRecord::RecordInvalid
          expect(context.error.to_s).to eq 'Validation failed: something'
          expect(context.full_error_message).to eq 'Validation failed: something'
        end

        context 'with call!' do
          it 'does not call GLExceptionNotifier' do
            expect(GLExceptionNotifier).not_to receive(:call)
            expect do
              test_class.call!(full_error_message_str:)
            end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: something')
          end

          it 'raises error with cause: CommandNoNotifyError' do
            test_class.call!(full_error_message_str:, set_no_notify:)
          rescue StandardError => e
            expect(e.class).to eq ActiveRecord::RecordInvalid
            expect(e.message).to eq 'Validation failed: something'
            expect(e.cause).to be_present
            expect(e.cause.class).to eq GLCommand::CommandNoNotifyError
            expect(e.cause.to_s).to eq 'Validation failed: something'
          end
        end
      end
    end

    context 'with full_error_message' do
      let(:set_no_notify) { false }
      let(:test_class) do
        Class.new(GLCommand::Callable) do
          allows :full_error_message_str, :set_no_notify

          def call
            context.instance_variable_set(:@no_notify, true) if set_no_notify

            context.full_error_message = full_error_message_str
          end
        end
      end

      it 'is truthy' do
        expect(context.errors).not_to be_present
        expect(context).to be_failure
        expect(context.error.class).to eq GLCommand::StopAndFail
        expect(context.full_error_message).to eq 'something'
        expect(context).not_to be_no_notify
      end

      context 'with no_notify' do
        let(:set_no_notify) { true }

        it 'is no_notify' do
          expect(context).to be_failure
          expect(context).to be_no_notify
          expect(context).not_to be_raise_errors
          expect(context.error.class).to eq GLCommand::StopAndFail
          expect(context.full_error_message).to eq 'something'
          expect(context.send(:inside_no_notify_error?)).to be_falsey
        end

        context 'with raise_errors' do
          it 'raises error with cause: CommandNoNotifyError' do
            test_class.call!(full_error_message_str:, set_no_notify:)
          rescue StandardError => e
            expect(e.class).to eq GLCommand::StopAndFail
            expect(e.to_s).to eq 'something'
            expect(e.cause).to be_present
            expect(e.cause.class).to eq GLCommand::CommandNoNotifyError
            expect(e.cause.to_s).to eq 'something'
          end
        end
      end

      context 'with blank full_error_message_str' do
        let(:full_error_message_str) { '' }

        it 'is falsey' do
          expect(context.errors).to be_blank
          expect(context).not_to be_failure
        end
      end
    end
  end

  describe 'call! within an GLCommand' do
    let(:array_duplicate_class) do
      Class.new(GLCommand::Callable) do
        requires :array

        returns new_array: Array

        def call
          result = ArrayPop.call!(array:)

          context.new_array = result.popped_array
        end
      end
    end

    let(:result) { array_duplicate_class.call(array:) }
    let(:array) { [1, 2] }

    it 'returns new_array' do
      expect(GLExceptionNotifier).not_to receive(:call)

      expect(result).to be_successful
      expect(result).not_to be_no_notify
      expect(result.new_array).to eq([1])
    end

    context 'with a failure inside' do
      it 'is not no_notify' do
        expect(GLExceptionNotifier).to receive(:call).once
        allow_any_instance_of(ArrayPop).to receive(:call) { raise 'Special Error!' }

        expect(result).to be_failure
        expect(result).not_to be_no_notify

        expect(result.new_array).to be_nil
        expect(result.full_error_message).to eq 'Special Error!'
      end
    end

    context 'with validation error' do
      let(:array) { [1, 2, 3, nil, 4] }
      let(:target_error_message) do
        'Validation failed: Array Must be an array with no blank items!'
      end

      it 'is no_notify' do
        expect(result).to be_failure
        expect(result.error).to be_present
        expect(result.error.cause).to be_present
        expect(result.send(:inside_no_notify_error?)).to be_truthy
        expect(result).to be_no_notify
        expect(result.new_array).to be_nil
        expect(result.full_error_message).to eq target_error_message
      end
    end
  end
  # rubocop:enable RSpec/MultipleExpectations
end
