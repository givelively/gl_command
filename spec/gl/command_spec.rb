# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GL::Command do
  it 'has a version number' do
    expect(GL::Command::VERSION).to be_a(String)
  end

  describe 'A Command class' do
    before do
      base_command = Class.new(Object) do
        require 'gl/command'
        include GL::Command
        include GL::Contract

        def call; end
      end
      stub_const('BaseCommand', base_command)
    end

    context 'when entering happy path' do
      subject(:test_class) do
        Class.new(BaseCommand) do
          def call
            context.foo = :bar
          end
        end
      end

      it { is_expected.to respond_to(:call) }
      it { is_expected.to respond_to(:context) }

      it 'returns a GL::Context' do
        expect(test_class.call).to be_a(GL::Context)
      end

      it 'is successful' do
        expect(test_class.call).to be_successful
      end

      it 'is not a failure' do
        expect(test_class.call).not_to be_failure
      end
    end

    describe 'A failing Command class' do
      subject(:test_class) do
        Class.new(BaseCommand) do
          def call
            non_existing_command
          end

          def rollback
            context.rolled_back = true
          end
        end
      end

      it 'returns a GL::Context with a non-empty errors object' do
        expect(test_class.call.errors).not_to be_empty
      end

      it 'is not successful' do
        expect(test_class.call).not_to be_successful
      end

      it 'is a failure' do
        expect(test_class.call).to be_failure
      end

      it 'calls `:rollback`' do
        expect(test_class.call(rolled_back: false).rolled_back).to be(true)
      end
    end

    describe 'a Command class called with invalid parameters' do
      subject(:test_class) do
        Class.new(BaseCommand) do
          def call; end
        end
      end

      it 'fails with a readable exception' do
        expect { test_class.call(:not_a_hash) }.to raise_error(GL::NotAContextError)
      end
    end

    describe 'Delegation' do
      context 'when using :requires' do
        context 'without type specification' do
          subject(:test_class) do
            Class.new(BaseCommand) do
              requires :foo

              def call
                raise if foo.blank?
              end
            end
          end

          it 'delegates variable to the context' do
            expect(test_class.call(foo: :bar)).to be_successful
          end
        end

        context 'with type specification' do
          subject(:test_class) do
            Class.new(BaseCommand) do
              requires foo: String

              def call
                raise if foo.blank?
              end
            end
          end

          it 'delegates variable to the context' do
            expect(test_class.call(foo: 'a')).to be_successful
          end
        end

        context 'with default option' do
          context 'with a value' do
            let(:test_class) do
              Class.new(BaseCommand) do
                requires foo: { type: String, default: 'default_foo' }
                requires :bar
              end
            end

            it 'uses the default value if none is given' do
              expect(test_class.call(bar: 'baz').foo).to eq 'default_foo'
            end

            it 'uses the given value' do
              expect(test_class.call(foo: 'given_foo', bar: 'baz').foo).to eq 'given_foo'
            end

            it 'uses a given nil value' do
              expect(test_class.call(foo: nil, bar: 'baz').foo).to be_nil
            end
          end

          context 'with a proc' do
            let(:test_class) do
              Class.new(BaseCommand) do
                requires foo: { type: String, default: -> { 'proc_foo' } }
                requires :bar
              end
            end

            it 'uses the default value if none is given' do
              expect(test_class.call(bar: 'baz').foo).to eq 'proc_foo'
            end
          end
        end
      end

      context 'when using :allows' do
        context 'without type specification' do
          subject(:test_class) do
            Class.new(BaseCommand) do
              allows :foo

              def call
                raise if foo.blank?
              end
            end
          end

          it 'delegates variable to the context' do
            expect(test_class.call(foo: :bar)).to be_successful
          end
        end

        context 'with type specification' do
          subject(:test_class) do
            Class.new(BaseCommand) do
              allows foo: String

              def call
                raise if foo.blank?
              end
            end
          end

          it 'delegates variable to the context' do
            expect(test_class.call(foo: 'a')).to be_successful
          end
        end
      end

      context 'when using :returns' do
        context 'without type specification' do
          subject(:test_class) do
            Class.new(BaseCommand) do
              returns :foo

              def call
                context.foo = :bar
                raise if foo.blank?
              end
            end
          end

          it 'delegates variable to the context' do
            expect(test_class.call).to be_successful
          end
        end

        context 'with type specification' do
          subject(:test_class) do
            Class.new(BaseCommand) do
              returns foo: String

              def call
                context.foo = 'a'
                raise if foo.blank?
              end
            end
          end

          it 'delegates variable to the context' do
            expect(test_class.call).to be_successful
          end
        end
      end

      context 'when using defaults' do
        context 'with inheritance' do
          let(:parent_class) do
            Class.new(BaseCommand) do
              allows number: { type: Integer, default: 1 }
            end
          end

          let(:child_class) do
            Class.new(parent_class) do
              allows name: { type: String, default: 'name' }
            end
          end

          it 'inherits defaults from parent' do
            context = child_class.call
            expect(context.number).to eq 1
            expect(context.name).to eq 'name'
          end

          it 'does not leak defaults to parent' do
            child_class.call
            context = parent_class.call
            expect(context.number).to eq 1
            expect(context.name).to be_nil
          end
        end
      end
    end
  end
end
