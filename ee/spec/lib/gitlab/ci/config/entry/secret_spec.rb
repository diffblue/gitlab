# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Secret do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      shared_examples 'configures secrets' do
        describe '#value' do
          it 'returns secret configuration' do
            expect(entry.value).to eq(config)
          end
        end

        describe '#valid?' do
          it 'is valid' do
            expect(entry).to be_valid
          end
        end
      end

      context 'when file setting is not defined' do
        let(:config) do
          {
            vault: {
              engine: { name: 'kv-v2', path: 'kv-v2' },
              path: 'production/db',
              field: 'password'
            }
          }
        end

        it_behaves_like 'configures secrets'
      end

      context 'when file setting is defined' do
        let(:config) do
          {
            vault: {
              engine: { name: 'kv-v2', path: 'kv-v2' },
              path: 'production/db',
              field: 'password'
            },
            file: true
          }
        end

        it_behaves_like 'configures secrets'
      end

      context 'when `token` is defined' do
        let(:config) do
          {
            vault: {
              engine: { name: 'kv-v2', path: 'kv-v2' },
              path: 'production/db',
              field: 'password'
            },
            token: '$TEST_ID_TOKEN'
          }
        end

        describe '#value' do
          it 'returns secret configuration' do
            expect(entry.value).to eq(
              {
                vault: {
                  engine: { name: 'kv-v2', path: 'kv-v2' },
                  path: 'production/db',
                  field: 'password'
                },
                token: '$TEST_ID_TOKEN'
              }
            )
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
        let(:config) { { foo: {} } }

        it 'reports error' do
          expect(entry.errors)
            .to include 'secret config contains unknown keys: foo'
        end
      end

      context 'when there is no vault entry' do
        let(:config) { {} }

        it 'reports error' do
          expect(entry.errors)
            .to include 'secret config missing required keys: vault'
        end
      end
    end
  end
end
