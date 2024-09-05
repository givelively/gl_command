require 'spec_helper'
require_relative '../../test_command_classes'

RSpec.describe GLCommand::Validatable do
  describe 'ArrayPop' do
    let(:array) { [1, 2, 3] }
    let(:result) { ArrayPop.call(array:) }

    it 'calls successfully' do
      expect(result).to be_successful
      expect(result.popped_array).to eq([1, 2])
      expect(result.popped_item).to eq 3
      expect(array).to eq([1, 2])
      expect(result.error).to be_nil
    end

    context 'without an array' do
      let(:array) { nil }
      let(:errors) { ["Array can't be blank", 'Array Must be an array with no blank items!'] }

      it 'adds an error' do
        expect(result).not_to be_successful
        expect(result.errors.full_messages).to eq(errors)
        expect(result.error.class).to eq(ActiveRecord::RecordInvalid)
      end
    end

    context 'with string array' do
      let(:array) { ['a', ''] }
      let(:target_error_message) do
        'Array Must be an array with no blank items!'
      end

      it 'adds an error' do
        expect(result).not_to be_successful
        expect(result.errors.full_messages).to eq(['Array Must be an array with no blank items!'])
        expect(result.error.to_s).to eq "Validation failed: #{target_error_message}"
        expect(result.full_error_message).to eq "Validation failed: #{target_error_message}"
        expect(result.error.class).to eq(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe 'validates numericality' do
    let(:test_validates_class) do
      Class.new(GLCommand::Callable) do
        # Need to set the class name for validatable, or it raises: Class name cannot be blank.
        def self.name
          'TestClass'
        end

        requires :number

        validates :number, numericality: { only_integer: true }, allow_nil: true

        def call; end
      end
    end

    context 'with call!' do
      it 'errors if called without keyword' do
        expect { test_validates_class.call! }.to raise_error(ArgumentError)
        expect { test_validates_class.call! }.to raise_error(/missing keyword: :number/)
      end

      it 'is successful if called with nil' do
        result = test_validates_class.call!(number: nil)
        expect(result).to be_successful
        expect(result.error).to be_nil
        expect(result.errors).to be_blank
      end

      it 'raises if called with string' do
        expect do
          test_validates_class.call!(number: 'N')
        end.to raise_error(ActiveRecord::RecordInvalid)
        expect do
          test_validates_class.call!(number: 'N')
        end.to raise_error(/Validation failed: Number is not a number/)
      end
    end
  end

  describe 'Manually adding errors' do
    let(:test_manual_class) do
      Class.new(GLCommand::Callable) do
        requires :number
        returns something: String

        validates :number, numericality: true

        # Need to set the class name for validatable, or it raises: Class name cannot be blank.
        def self.name
          'TestClassManual'
        end

        def call
          unless number.is_a?(Integer)
            # This DOES NOT stop execution!
            errors.add(:base, 'Number must be an integer')
          end

          context.something = "Some #{number}"
        end
      end
    end

    it 'assigns something' do
      result = test_manual_class.call(number: 2)
      expect(result).to be_successful
      expect(result.something).to eq 'Some 2'
    end

    context 'with number: float' do
      it 'is failure, but assigns something' do
        result = test_manual_class.call(number: 1.2)
        expect(result).to be_a_failure
        expect(result.error.class).to eq ActiveRecord::RecordInvalid
        expect(result.full_error_message).to eq 'Validation failed: Number must be an integer'
        expect(result.something).to eq 'Some 1.2'
      end

      it 'raises ActiveRecord::RecordInvalid with call!' do
        expect do
          test_manual_class.call!(number: 1.2)
        end.to raise_error(ActiveRecord::RecordInvalid)
        expect do
          test_manual_class.call!(number: 1.2)
        end.to raise_error(/Validation failed: Number must be an integer/)
      end
    end

    context 'with number: blank' do
      it 'errors if called without keyword' do
        expect { test_manual_class.call! }.to raise_error(ArgumentError)
        expect { test_manual_class.call! }.to raise_error(/missing keyword: :number/)
        expect(test_manual_class.call).to be_a_failure
      end

      it 'is failure if called with nil' do
        result = test_manual_class.call(number: '')
        expect(result).to be_a_failure
        expect(result.error.class).to eq ActiveRecord::RecordInvalid
        expect(result.full_error_message).to eq 'Validation failed: Number is not a number'
        expect(result.something).to be_nil
      end

      it 'does not call GLExceptionNotifier' do
        expect(GLExceptionNotifier).not_to receive(:call)
        result = test_manual_class.call(number: [])
        expect(result).to be_a_failure
        expect(result.full_error_message).to eq 'Validation failed: Number is not a number'
        expect(result.something).to be_nil
      end
    end
  end

  describe 'multiple errors' do
    let(:test_multiple_class) do
      Class.new(GLCommand::Callable) do
        requires :number, :string, :size
        returns something: String

        validates :number, numericality: true
        validates :string, format: {
          with: /\A[a-zA-Z]+\z/, message: 'only allows letters'
        }
        validates :size, inclusion: { in: %w[small medium large],
                                      message: '%<value>s is not a valid size' }

        # Need to set the class name for validatable, or it raises: Class name cannot be blank.
        def self.name
          'TestClassMultiple'
        end

        def call
          "Number: #{number}, String: #{string}, Size: #{size}"
        end
      end
    end

    it 'is successful' do
      result = test_multiple_class.call(number: '2', string: 'a', size: 'small')
      expect(result).to be_successful
      expect(result.something).to eq 'Number: 2, String: a, Size: small'
      expect(result.errors).to be_blank
    end

    context 'with multiple validation errors' do
      let(:target_error_message) do
        'Validation failed: Number is not a number, String only allows letters, ' \
          'Size xl is not a valid size'
      end

      it 'is unsuccessful' do
        result = test_multiple_class.call(number: 'a', string: '2', size: 'xl')
        expect(result).not_to be_successful
        expect(result.full_error_message).to eq target_error_message
      end
    end
  end

  describe 'errors' do
    let(:errors_command) do
      Class.new(GLCommand::Callable) do
        allows :validation_error, :skip_raising

        def call
          errors.add(:base, validation_error) if validation_error.present?
          raise 'Raised error message!' unless skip_raising == true
        end
      end
    end
    let(:result) { errors_command.call(validation_error:, skip_raising:) }
    let(:validation_error) { nil }
    let(:skip_raising) { false }

    it 'returns the errors' do
      expect(result).to be_a_failure
      expect(result.errors.count).to eq 1
      # make it explicit that this is a full_error_message
      expect(result.full_error_message).to eq 'Raised error message!'
      expect(result.errors.full_messages).to eq(['Command Error: Raised error message!'])
    end

    context 'with validation_error' do
      let(:validation_error) { 'validation error' }

      it 'returns the errors' do
        expect(result).to be_a_failure
        expect(result.errors.count).to eq 2
        # make it explicit that this is a full_error_message
        expect(result.full_error_message).to eq 'Raised error message!'
        expect(result.errors.full_messages.sort).to eq(['Command Error: Raised error message!', 'validation error'])
      end
    end

    context 'with skip_raising' do
      let(:validation_error) { 'validation error' }
      let(:skip_raising) { true }
      it 'returns with just the validation error' do
        expect(result).to be_a_failure
        expect(result.errors.count).to eq 1
        # make it explicit that this is a full_error_message
        expect(result.full_error_message).to eq 'Validation failed: validation error'
        expect(result.errors.full_messages.sort).to eq(['validation error'])
      end
    end
  end

  # TODO: include active record model

  # describe 'Record raises ActiveRecord::RecordInvalid in call' do
  #   let(:test_call_with_invalid) do
  #     Class.new(GLCommand::Callable) do
  #       # Need to set the class name for validatable, or it raises: Class name cannot be blank.
  #       def self.name
  #         'TestCallWithInvalid'
  #       end

  #       def call
  #         errors.add(:base, 'Cart must exist') # Ensure this isn't duplicated
  #         CartCustomer.create!
  #       end
  #     end
  #   end
  #   let(:target_errors) do
  #     ['Cart must exist', "Cart can't be blank", "Customer can't be blank"]
  #   end

  #   it "adds the record's errors to context.errors but doesn't duplicate them" do
  #     result = test_call_with_invalid.call
  #     expect(result).to be_failure
  #     expect(result.errors.full_messages).to match_array target_errors
  #     expect(result.full_error_message).to eq "Validation failed: #{target_errors.join(', ')}"
  #   end
  # end
end
