require 'rails_helper'
require_relative '../../test_command_classes'

RSpec.describe GLCommand::Callable do
  context 'with array_add_class' do
    let(:array) { [1, 2, 3, 4] }

    describe 'call' do
      it 'adds to the array' do
        result = ArrayAdd.call(array:, item: 6)
        expect(result).to be_successful
        expect(array).to eq([1, 2, 3, 4, 6])
        expect(result.new_array).to eq([1, 2, 3, 4, 6])
      end
    end

    describe 'rollback' do
      before do
        allow_any_instance_of(ArrayAdd).to receive(:do_another_thing) {
                                             raise 'Test Error'
                                           }
      end

      def failure_expectations(result)
        expect(result).to be_failure
        expect(result.error.to_s).to match(/Test Error/)
        expect(array).to eq([1, 2, 3, 4])
        expect(result.new_array).to eq([1, 2, 3, 4, 6])
      end

      it 'runs rollback if there is a failure' do
        expect(GLExceptionNotifier).to receive(:call).once
        result = ArrayAdd.call(array:, item: 6)
        failure_expectations(result)
        expect(result).not_to be_raise_error
      end

      context 'with call!' do
        it 'runs rollback and raises' do
          expect do
            expect(GLExceptionNotifier).not_to receive(:call)
            result = ArrayAdd.call!(array:, item: 6)
            failure_expectations(result)
            expect(result).to be_raise_error
          end.to raise_error(/Test Error/)
        end
      end
    end
  end

  describe 'TestNormalizeEin' do
    let(:ein) { '81-0693451' }

    describe 'arguments and returns' do
      it 'provides arguments returns' do
        expect(TestNormalizeEin.arguments).to eq([:string])
        expect(TestNormalizeEin.returns).to eq([:ein])
      end
    end

    describe 'call' do
      it 'returns the expected result' do
        result = TestNormalizeEin.call(string: '001111111')
        expect(result).to be_successful
        expect(result.error).to be_nil
        expect(result.ein).to eq '00-1111111'
        expect(result).not_to be_raise_errors
      end
    end

    describe 'context inspect' do
      let(:target) do
        '<GLCommand::Context error=nil, success=true, ' \
          'arguments={string: nil}, returns={ein: nil}, class=TestNormalizeEin>'
      end

      it 'renders inspect as expected' do
        expect(TestNormalizeEin.build_context.inspect).to eq target
      end
    end
  end

  describe 'CreateTestNpo' do
    let(:ein) { '81-0693451' }

    describe 'call' do
      let(:result) { CreateTestNpo.call(ein:) }

      it 'returns the expected result' do
        expect(result).to be_successful
        expect(result.error).to be_nil
        expect(result.test_npo.ein).to eq ein
        expect(result.to_h).to eq({ ein:, test_npo: result.test_npo })
        expect(result).not_to be_raise_errors
      end

      it 'has the returns and arguments' do
        expect(result).to be_successful
        expect(result.arguments).to eq({ ein: })
        expect(result.returns).to eq({ test_npo: result.test_npo })
      end
    end

    describe 'context inspect' do
      let(:target) do
        '<GLCommand::Context error=nil, success=true, ' \
          'arguments={ein: nil}, returns={test_npo: nil}, class=CreateTestNpo>'
      end

      it 'renders inspect as expected' do
        expect(CreateTestNpo.build_context.inspect).to eq target
      end
    end
  end

  describe 'square_root_class, assign through actual return' do
    let(:square_root_class) do
      Class.new(GLCommand::Callable) do
        requires number: Numeric

        returns :root

        def call
          Math.sqrt(number)
        end
      end
    end

    describe '#context' do
      it 'can be used to stub' do
        result = square_root_class.build_context(number: 4, root: 16)
        expect(result).to be_successful
        expect(result.number).to eq 4
        expect(result.root).to eq 16
      end

      it 'raises when passed an unknown argument or returns' do
        expect do
          square_root_class.build_context(some_weird_arg: false)
        end.to raise_error(ArgumentError)
      end
    end

    describe 'call' do
      let(:number) { 4 }
      let(:result) { square_root_class.call(number:) }

      it 'squares the number' do
        expect(result.arguments).to eq({ number: 4 })
        expect(result.root).to eq 2
        expect(result).to be_successful
        expect(result.to_h).to eq({ number:, root: 2 })
      end

      context 'with number: nil' do
        let(:number) { nil }

        it 'returns error' do
          expect(result).to be_a_failure
          expect(result.full_error_message).to eq ':number is not a Numeric'
        end
      end
    end

    describe 'failure' do
      it 'is a failure if there is an error' do
        result = square_root_class.call(number: -4)
        expect(result).to be_failure
        expect(result.error).to be_present
        expect(result.error.to_s).to match(/Numerical argument is out of domain/)
      end

      context 'with call!' do
        it 'raises' do
          expect do
            square_root_class.call!(number: -4)
          end.to raise_error(/Numerical argument is out of domain/)
        end
      end
    end
  end

  describe 'returns_clobber_class' do
    let(:returns_clobber_class) do
      Class.new(GLCommand::Callable) do
        requires :array, :item

        returns :new_array, :array

        def call
          context.new_array = array.dup.push(item)
          context.array = context.new_array
        end
      end
    end

    let(:array) { [1, 2, 3, 4] }
    let(:new_array) { [1, 2, 3, 4, 6] }
    let(:result) { returns_clobber_class.call(array:, item: 6) }

    it 'adds to the array' do
      expect(result).to be_successful
      expect(array).to eq([1, 2, 3, 4])
      expect(result.new_array).to eq new_array
      expect(result.array).to eq new_array
    end

    it 'arguments are clobbered' do
      expect(result.arguments[:array]).to eq new_array
      expect(result.to_h).to eq({ array: new_array, item: 6, new_array: })
    end
  end

  describe 'stop_and_fail!' do
    let(:test_class) do
      Class.new(GLCommand::Callable) do
        requires :number

        allows :fail_error

        returns :revised_number

        def call
          context.revised_number = number * 2
          if fail_error
            stop_and_fail!(fail_error, no_notify: true)
          else
            stop_and_fail!
          end
          # This shouldn't ever happen, because stop_and_fail
          raise 'SPECIAL ERROR'
        end

        def rollback
          context.revised_number = context.number / 2
        end
      end
    end

    let(:number) { 4 }
    let(:fail_error) { nil }
    let(:result) { test_class.call(number:, fail_error:) }

    describe 'call' do
      it 'rolls back' do
        expect(result.arguments).to eq({ number: 4, fail_error: nil })
        expect(result.revised_number).to eq 2
        expect(result).to be_failure
        expect(result.error.class).to eq GLCommand::StopAndFail
      end

      it 'calls exception_notifier once' do
        expect(GLExceptionNotifier).to receive(:call).once

        expect(result).to be_failure
        expect(result.full_error_message).to eq 'GLCommand::StopAndFail'
      end

      context 'when fail_error string' do
        let(:fail_error) { 'some error message' }

        it 'assigns full_error_message' do
          expect(GLExceptionNotifier).not_to receive(:call)
          expect(result).to be_failure
          expect(result.error.class).to eq GLCommand::StopAndFail
          expect(result.full_error_message).to eq fail_error
        end
      end

      context 'when fail_error array' do
        let(:fail_error) { ['some error', 'message'] }

        it 'assigns full_error_message' do
          expect(GLExceptionNotifier).not_to receive(:call)
          expect(result).to be_failure
          expect(result.error.class).to eq GLCommand::StopAndFail
          expect(result.full_error_message).to eq 'some error, message'
        end
      end

      context 'when Exception' do
        let(:fail_error) { ActiveRecord::RecordNotFound }

        it 'assigns full_error_message' do
          expect(GLExceptionNotifier).not_to receive(:call)
          expect(result).to be_failure
          expect(result.error.class).to eq ActiveRecord::RecordNotFound
          expect(result.full_error_message).to eq 'ActiveRecord::RecordNotFound'
        end
      end
    end

    describe 'call!' do
      it 'raises, does not call GLExceptionNotifier' do
        expect(GLExceptionNotifier).not_to receive(:call)

        expect do
          test_class.call!(number:)
        end.to raise_error(GLCommand::StopAndFail)
      end
    end

    context 'with no_notify' do
      let(:test_class) do
        Class.new(GLCommand::Callable) do
          returns :something

          def call
            stop_and_fail!(no_notify: true)
          end
        end
      end
      let(:result) { test_class.call }

      it 'does not assign context and loop' do
        expect(GLExceptionNotifier).not_to receive(:call)

        expect(result.error).to be_present
        expect(result).to be_failure
        expect(result.something).to be_blank
      end
    end

    context 'with no return assigned' do
      let(:test_class) do
        Class.new(GLCommand::Callable) do
          returns :something

          def call
            stop_and_fail!
          end
        end
      end
      let(:result) { test_class.call }

      it 'does not assign context and loop' do
        expect(GLExceptionNotifier).to receive(:call).once
        expect(result.error).to be_present
        expect(result).to be_failure
        expect(result).not_to be_no_notify
        expect(result.something).to be_blank
      end
    end
  end

  describe 'command with positional_parameter' do
    let(:test_class) do
      Class.new(GLCommand::Callable) do
        def call(something, another_thing:); end
      end
    end

    it 'raises a legible error' do
      expect do
        test_class.call('fff', another_thing: 'herere')
      end.to raise_error(/only.*keyword/i)
    end
  end

  describe 'command class without call' do
    let(:test_class) { Class.new(described_class) }

    it 'raises a legible error' do
      expect do
        test_class.call!
      end.to raise_error(/define.*call.*method/i)
    end
  end

  describe 'duplicate argument' do
    let(:test_class) do
      Class.new(GLCommand::Callable) do
        requires array: Array
        allows :array
      end
    end

    it 'raises' do
      expect do
        test_class.call(array: [])
      end.to raise_error(/duplicated/i)
    end
  end

  describe 'argument that is a reserved word' do
    let(:test_class) do
      Class.new(GLCommand::Callable) do
        requires :callable
      end
    end

    it 'raises' do
      expect do
        test_class.call(callable: [])
      end.to raise_error(/reserved/i)
    end
  end

  describe 'return that is a reserved word' do
    let(:test_class) do
      Class.new(GLCommand::Callable) do
        returns :error

        def call; end
      end
    end
    let(:target_error) do
      ['You used reserved word(s): [:error]',
       '(check GLCommand::Callable::RESERVED_WORDS for the full list)'].join("\n")
    end

    it 'raises' do
      expect do
        test_class.call(whatever: 'something')
      end.to raise_error(target_error)
    end
  end

  describe 'arguments and returns' do
    let(:test_class) do
      Class.new(GLCommand::Callable) do
        requires array: Array

        allows :something, other: String

        returns :something, new_array: Array

        def call; end
      end
    end

    it 'returns arguments and returns' do
      expect(test_class.arguments).to eq(%i[array something other])
      expect(test_class.instance_variable_get(:@requires)).to eq({ array: Array })
      expect(test_class.instance_variable_get(:@allows)).to eq({ something: nil, other: String })
      expect(test_class.instance_variable_get(:@returns)).to eq(%i[something new_array])
    end

    it 'is successful with a blank array' do
      result = test_class.call(array: [])
      expect(result).to be_successful
      expect(result.full_error_message).to be_blank
    end

    it 'is unsuccessful with invalid keyword' do
      result = test_class.call(array: [], not_array: [1])
      expect(result).not_to be_successful

      expect(result.error.class).to eq ArgumentError
      expect(result.error.to_s).to match(/unknown keyword: :not_array/)
    end

    it 'is unsuccessful without required keyword' do
      result = test_class.call
      expect(result).not_to be_successful
      expect(result.error.class).to eq ArgumentError
      expect(result.error.to_s).to match(/missing keyword: :array/)
    end

    context 'with call!' do
      it 'errors if called with a different keyword' do
        # Copy the errors raised from this:
        # def cool(array:, n:); end
        # cool(n: 2, zzz: 'ffff')
        expect { test_class.call!(not_array: [1]) }.to raise_error(ArgumentError)
        expect { test_class.call!(not_array: [1]) }.to raise_error(/missing keyword: :array/)
      end

      it 'errors if called with unknown keyword' do
        # Copy the errors raised from this:
        # def cool(array:); end
        # cool(array: ['1'], n: 'c')
        expect { test_class.call!(array: [1], not_array: [1]) }.to raise_error(ArgumentError)
        expect do
          test_class.call!(array: [1], not_array: [1])
        end.to raise_error(/unknown keyword: :not_array/)
      end

      it 'errors if called with a non array' do
        expect { test_class.call!(array: 'dddd') }.to raise_error(GLCommand::ArgumentTypeError)
        expect { test_class.call!(array: 'dddd') }.to raise_error(/:array is not a Array/)
      end

      it 'errors if called allows of invalid type' do
        expect do
          test_class.call!(array: [1], other: [2])
        end.to raise_error(GLCommand::ArgumentTypeError)
        expect { test_class.call!(array: [1], other: [2]) }.to raise_error(/:other is not a String/)
      end
    end
  end

  describe 'strong_attributes for allows' do
    let(:test_class) do
      Class.new(GLCommand::Callable) do
        allows :something, other: String

        def call; end
      end
    end

    it 'validates type if passed' do
      result = test_class.call(other: 1)
      expect(result).to be_a_failure
      expect(result.error.class).to eq GLCommand::ArgumentTypeError
      expect(result.full_error_message).to eq ':other is not a String'
    end

    it 'is successful with blank' do
      result = test_class.call(other: '')
      expect(result).to be_a_success
      expect(result.full_error_message).to be_nil
    end

    it 'does not validate type if nil' do
      test_class.call!(other: nil)
      result = test_class.call(other: nil)
      expect(result).to be_a_success
    end
  end

  describe 'delegates arguments and returns' do
    let(:test_class) do
      Class.new(GLCommand::Callable) do
        requires :array

        returns :new_array, :removed_item

        def call
          context.new_array = array.dup
          new_array.pop
          add_item!
        end

        private

        def add_item!
          context.removed_item = array.last
        end
      end
    end

    it 'returns new_array' do
      result = test_class.call(array: [1, 2])
      expect(result).to be_successful
      expect(result.new_array).to eq([1])
      expect(result.removed_item).to eq(2)
    end

    describe 'arguments and returns' do
      it 'returns arguments' do
        expect(test_class.arguments).to eq([:array])
        expect(test_class.instance_variable_get(:@requires)).to eq({ array: nil })
        expect(test_class.instance_variable_get(:@allows)).to eq({})
        expect(test_class.instance_variable_get(:@returns)).to eq(%i[new_array removed_item])
      end
    end

    context 'with raise_errors: true' do
      it 'errors if called without keyword' do
        expect { test_class.call('string', raise_errors: true) }.to raise_error(ArgumentError)
      end

      it 'errors if called with a different keyword' do
        expect do
          test_class.call(not_array: [1], raise_errors: true)
        end.to raise_error(ArgumentError)
      end
    end

    context 'with call!' do
      it 'errors if called without keyword' do
        expect { test_class.call!([1]) }.to raise_error(ArgumentError)
      end

      it 'errors if called with a different keyword' do
        expect { test_class.call!(not_array: [1]) }.to raise_error(ArgumentError)
      end
    end
  end
end
