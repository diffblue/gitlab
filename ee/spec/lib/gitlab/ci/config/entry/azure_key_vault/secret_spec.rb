# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::AzureKeyVault::Secret, feature_category: :secrets_management do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    before do
      entry.compose!
    end

    shared_examples 'config is a hash and valid' do
      context 'when config is a hash' do
        let(:config) { hash_config }

        describe '#value' do
          it 'returns Vault secret configuration' do
            expect(entry.value).to eq(hash_config)
          end
        end

        describe '#valid?' do
          it 'is valid' do
            expect(entry).to be_valid
          end
        end
      end
    end

    context 'when entry config value is correct' do
      context 'when version is not nil' do
        let(:hash_config) do
          {
            name: 'name',
            version: 'version'
          }
        end

        it_behaves_like 'config is a hash and valid'
      end

      context 'when version is nil' do
        let(:hash_config) do
          {
            name: 'name',
            version: nil
          }
        end

        it_behaves_like 'config is a hash and valid'
      end

      context 'when version is not defined' do
        let(:config) do
          {
            name: 'name'
          }
        end

        describe '#value' do
          it 'returns Vault secret configuration' do
            expect(entry.value).to eq({
              name: 'name',
              version: nil
            })
          end
        end

        describe '#valid?' do
          it 'is valid' do
            expect(entry).to be_valid
          end
        end
      end
    end
  end

  context 'when entry value is not correct' do
    describe '#errors' do
      context 'when there is an unknown key present' do
        let(:config) { { foo: :bar } }

        it 'reports error' do
          expect(entry.errors)
            .to include 'secret config contains unknown keys: foo'
        end
      end

      context 'when name is not present' do
        let(:config) { {} }

        it 'reports error' do
          expect(entry.errors)
            .to include 'secret name can\'t be blank'
        end
      end

      context 'when config is not a hash' do
        let(:config) { "" }

        it 'reports error' do
          expect(entry.errors)
            .to include 'secret config should be a hash'
        end
      end
    end
  end
end
