# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JwtController, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:actions) { ['pull'] }
  let(:expected_actions) { actions }
  let(:scope) { "repository:#{project.full_path}:#{expected_actions.join(',')}" }
  let(:service_name) { 'container_registry' }
  let(:headers) { { authorization: credentials(user.username, user.password) } }
  let(:parameters) { { account: user.username, client_id: 'docker', offline_token: true, service: service_name, scope: scope } }

  shared_examples 'successful JWT auth' do
    it 'allows access' do
      get '/jwt/auth', params: parameters, headers: headers

      expect(response).to have_gitlab_http_status(:ok)
      expect(token_response['access']).to be_present
      expect(token_access['actions']).to eq expected_actions
      expect(token_access['type']).to eq 'repository'
      expect(token_access['name']).to eq project.full_path
    end
  end

  shared_examples 'unsuccessful JWT auth' do
    it 'denies access' do
      get '/jwt/auth', params: parameters, headers: headers

      expect(response).to have_gitlab_http_status(:ok)
      expect(token_response['access']).to eq []
    end
  end

  context 'with IP restriction' do
    let_it_be(:project) { create(:project, :private, group: group) }
    let_it_be(:group_deploy_token) { create(:deploy_token, :group, groups: [group], read_registry: true, write_registry: true) }
    let_it_be(:project_deploy_token) { create(:deploy_token, projects: [project], read_registry: true, write_registry: true) }

    let(:actions) { %w[push pull] }

    before do
      project.add_developer(user)
      stub_container_registry_config(enabled: true, key: 'spec/fixtures/x509_certificate_pk.key')
      allow(Gitlab::IpAddressState).to receive(:current).and_return('192.168.0.2')
      stub_licensed_features(group_ip_restriction: true)
    end

    context 'group with restriction' do
      using RSpec::Parameterized::TableSyntax

      before do
        create(:ip_restriction, group: group, range: range)
      end

      shared_examples 'successful JWT auth with token' do
        let(:headers) { { authorization: credentials(token.username, token.token) } }

        where(:read, :write, :expected_actions) do
          true  | false | %w[pull]
          false | true  | %w[push]
          true  | true  | %w[push pull]
        end

        with_them do
          before do
            token.update!(read_registry: read, write_registry: write)
          end

          it_behaves_like 'successful JWT auth'
        end
      end

      context 'address is within the range' do
        let(:range) { '192.168.0.0/24' }

        it_behaves_like 'successful JWT auth'

        context 'with project deploy token' do
          let(:token) { project_deploy_token }

          it_behaves_like 'successful JWT auth with token'
        end

        context 'with group deploy token' do
          let(:token) { group_deploy_token }

          it_behaves_like 'successful JWT auth with token'
        end
      end

      context 'address is outside the range' do
        let(:range) { '10.0.0.0/8' }

        it_behaves_like 'unsuccessful JWT auth'

        context 'with deploy token credentials' do
          let(:headers) { { authorization: credentials(token.username, token.token) } }

          context 'with project deploy token' do
            let(:token) { project_deploy_token }

            it_behaves_like 'unsuccessful JWT auth'
          end

          context 'with group deploy token' do
            let(:token) { group_deploy_token }

            it_behaves_like 'unsuccessful JWT auth'
          end
        end
      end
    end
  end

  context 'authenticating against container registry' do
    let_it_be(:project) { create(:project, :private, group: group) }

    before do
      project.add_reporter(user)
      stub_container_registry_config(enabled: true, issuer: 'gitlab-issuer', key: 'spec/fixtures/x509_certificate_pk.key')
    end

    context 'when Group SSO is enforced' do
      let!(:saml_provider) { create(:saml_provider, enforced_sso: true, group: group) }
      let!(:identity) { create(:group_saml_identity, saml_provider: saml_provider, user: user) }

      it_behaves_like 'successful JWT auth'
    end
  end

  def credentials(login, password)
    ActionController::HttpAuthentication::Basic.encode_credentials(login, password)
  end

  def token_response
    JWT.decode(json_response['token'], nil, false).first
  end

  def token_access
    token_response['access']&.first
  end
end
