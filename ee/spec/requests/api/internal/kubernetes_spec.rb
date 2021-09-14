# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Kubernetes do
  let(:jwt_auth_headers) do
    jwt_token = JWT.encode({ 'iss' => Gitlab::Kas::JWT_ISSUER }, Gitlab::Kas.secret, 'HS256')

    { Gitlab::Kas::INTERNAL_API_REQUEST_HEADER => jwt_token }
  end

  let(:jwt_secret) { SecureRandom.random_bytes(Gitlab::Kas::SECRET_LENGTH) }
  let(:agent_token) { create(:cluster_agent_token) }
  let(:agent_token_headers) { { 'Authorization' => "Bearer #{agent_token.token}" } }
  let(:agent) { agent_token.agent }
  let(:project) { agent.project }

  def send_request(params: {}, headers: agent_token_headers)
    case method
    when :post
      post api(api_url), params: params, headers: headers.reverse_merge(jwt_auth_headers)
    when :put
      put api(api_url), params: params, headers: headers.reverse_merge(jwt_auth_headers)
    end
  end

  before do
    allow(Gitlab::Kas).to receive(:secret).and_return(jwt_secret)
  end

  shared_examples 'authorization' do
    context 'not authenticated' do
      it 'returns 401' do
        send_request(headers: { Gitlab::Kas::INTERNAL_API_REQUEST_HEADER => '' })

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'kubernetes_agent_internal_api feature flag disabled' do
      before do
        stub_feature_flags(kubernetes_agent_internal_api: false)
      end

      it 'returns 404' do
        send_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'agent authentication' do
    it 'returns 401 if Authorization header not sent' do
      send_request(headers: {})

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    it 'returns 401 if Authorization is for non-existent agent' do
      send_request(headers: { 'Authorization' => 'Bearer NONEXISTENT' })

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe 'POST /internal/kubernetes/modules/cilium_alert' do
    let(:method) { :post }
    let(:api_url) { '/internal/kubernetes/modules/cilium_alert' }

    include_examples 'authorization'
    include_examples 'agent authentication'

    context 'is authenticated for an agent' do
      before do
        stub_licensed_features(cilium_alerts: true)
      end

      let(:payload) { build(:network_alert_payload) }

      it 'returns no_content for valid alert payload' do
        send_request(params: { alert: payload })

        expect(AlertManagement::Alert.count).to eq(1)
        expect(AlertManagement::Alert.all.first.project).to eq(agent.project)
        expect(response).to have_gitlab_http_status(:success)
      end

      context 'when payload is invalid' do
        let(:payload) { { temp: {} } }

        it 'returns bad request' do
          send_request(params: { alert: payload })
          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when feature is not available' do
        before do
          stub_licensed_features(cilium_alerts: false)
        end

        it 'returns forbidden for non licensed project' do
          send_request(params: { alert: payload })

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'PUT /internal/kubernetes/modules/starboard_vulnerability' do
    let(:method) { :put }
    let(:api_url) { '/internal/kubernetes/modules/starboard_vulnerability' }

    include_examples 'authorization'
    include_examples 'agent authentication'

    context 'is authenticated for an agent' do
      before do
        stub_licensed_features(security_dashboard: true)
        project.add_maintainer(agent.created_by_user)
      end

      let(:payload) do
        {
          vulnerability: {
            name: 'CVE-123-4567 in libc',
            severity: 'high',
            confidence: 'unknown',
            location: {
              kubernetes_resource: {
                namespace: 'production',
                kind: 'deployment',
                name: 'nginx',
                container: 'nginx'
              }
            },
            identifiers: [
              {
                type: 'cve',
                name: 'CVE-123-4567',
                value: 'CVE-123-4567'
              }
            ]
          },
          scanner: {
            id: 'starboard_trivy',
            name: 'Trivy (via Starboard Operator)',
            vendor: 'GitLab'
          }
        }
      end

      it 'returns ok when a vulnerability is created' do
        send_request(params: payload)

        expect(response).to have_gitlab_http_status(:ok)
        expect(Vulnerability.count).to eq(1)
        expect(Vulnerability.all.first.finding.name).to eq(payload[:vulnerability][:name])
      end

      context 'when payload is invalid' do
        let(:payload) { { vulnerability: 'invalid' } }

        it 'returns bad request' do
          send_request(params: payload)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when feature is not available' do
        before do
          stub_licensed_features(security_dashboard: false)
        end

        it 'returns forbidden for non licensed project' do
          send_request(params: payload)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end
end
