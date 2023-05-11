# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::BuildRunnerPresenter, feature_category: :secrets_management do
  subject(:presenter) { described_class.new(ci_build) }

  describe '#secrets_configuration' do
    let!(:ci_build) { create(:ci_build, secrets: secrets) }

    context 'build has no secrets' do
      let(:secrets) { {} }

      it 'returns empty hash' do
        expect(presenter.secrets_configuration).to eq({})
      end
    end

    context 'build has secrets' do
      let(:secrets) do
        {
          DATABASE_PASSWORD: {
            file: true,
            vault: {
              engine: { name: 'kv-v2', path: 'kv-v2' },
              path: 'production/db',
              field: 'password'
            }
          }
        }
      end

      context 'Vault server URL' do
        let(:vault_server) { presenter.secrets_configuration.dig('DATABASE_PASSWORD', 'vault', 'server') }

        context 'VAULT_SERVER_URL CI variable is present' do
          it 'returns the URL' do
            create(:ci_variable, project: ci_build.project, key: 'VAULT_SERVER_URL', value: 'https://vault.example.com')

            expect(vault_server.fetch('url')).to eq('https://vault.example.com')
          end
        end

        context 'VAULT_SERVER_URL CI variable is not present' do
          it 'returns nil' do
            expect(vault_server.fetch('url')).to be_nil
          end
        end
      end

      context 'Vault auth role' do
        let(:vault_auth_data) { presenter.secrets_configuration.dig('DATABASE_PASSWORD', 'vault', 'server', 'auth', 'data') }

        context 'VAULT_AUTH_ROLE CI variable is present' do
          it 'contains the  auth role' do
            create(:ci_variable, project: ci_build.project, key: 'VAULT_AUTH_ROLE', value: 'production')

            expect(vault_auth_data.fetch('role')).to eq('production')
          end
        end

        context 'VAULT_AUTH_ROLE CI variable is not present' do
          it 'skips the auth role' do
            expect(vault_auth_data).not_to have_key('role')
          end
        end
      end

      context 'Vault auth path' do
        let(:vault_auth) { presenter.secrets_configuration.dig('DATABASE_PASSWORD', 'vault', 'server', 'auth') }

        context 'VAULT_AUTH_PATH CI variable is present' do
          it 'contains user defined auth path' do
            create(:ci_variable, project: ci_build.project, key: 'VAULT_AUTH_PATH', value: 'custom/path')

            expect(vault_auth.fetch('path')).to eq('custom/path')
          end
        end

        context 'VAULT_AUTH_PATH CI variable is not present' do
          it 'contains the default auth path' do
            expect(vault_auth.fetch('path')).to eq('jwt')
          end
        end
      end

      context 'Vault namespace' do
        let(:vault_server) { presenter.secrets_configuration.dig('DATABASE_PASSWORD', 'vault', 'server') }

        context 'VAULT_NAMESPACE CI variable is present' do
          it 'contains user defined namespace' do
            create(:ci_variable, project: ci_build.project, key: 'VAULT_NAMESPACE', value: 'custom_namespace')

            expect(vault_server.fetch('namespace')).to eq('custom_namespace')
          end
        end

        context 'VAULT_NAMESPACE CI variable is not present' do
          it 'returns nil' do
            expect(vault_server.fetch('namespace')).to be_nil
          end
        end
      end

      context 'File variable configuration' do
        subject { presenter.secrets_configuration.dig('DATABASE_PASSWORD') }

        it 'contains the file configuration directive' do
          expect(subject.fetch('file')).to be_truthy
        end
      end

      context 'when there are ID tokens available' do
        before do
          rsa_key = OpenSSL::PKey::RSA.generate(3072).to_s
          stub_application_setting(ci_jwt_signing_key: rsa_key)
          ci_build.id_tokens = {
            'VAULT_ID_TOKEN_1' => { id_token: { aud: 'https://gitlab.test' } },
            'VAULT_ID_TOKEN_2' => { id_token: { aud: 'https://gitlab.link' } }
          }
          ci_build.runner = build_stubbed(:ci_runner)
        end

        it 'adds the first ID token to the Vault server payload' do
          jwt = presenter.secrets_configuration.dig('DATABASE_PASSWORD', 'vault', 'server', 'auth', 'data', 'jwt')

          expect(jwt).to eq('$VAULT_ID_TOKEN_1')
        end

        context 'when the token variable is specified for the vault secret' do
          let(:secrets) do
            {
              DATABASE_PASSWORD: {
                file: true,
                token: '$VAULT_ID_TOKEN_2',
                vault: {
                  engine: { name: 'kv-v2', path: 'kv-v2' },
                  path: 'production/db',
                  field: 'password'
                }
              }
            }
          end

          it 'uses the specified token variable' do
            jwt = presenter.secrets_configuration.dig('DATABASE_PASSWORD', 'vault', 'server', 'auth', 'data', 'jwt')

            expect(jwt).to eq('$VAULT_ID_TOKEN_2')
          end
        end
      end
    end
  end
end
