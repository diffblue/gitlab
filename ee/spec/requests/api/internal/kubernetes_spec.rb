# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::Kubernetes, feature_category: :deployment_management do
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

  describe 'PUT /internal/kubernetes/modules/starboard_vulnerability' do
    let(:method) { :put }
    let(:api_url) { '/internal/kubernetes/modules/starboard_vulnerability' }
    let(:cluster_agent) { create(:cluster_agent, project: project) }

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
            severity: 'High',
            location: {
              image: 'index.docker.io/library/nginx:latest',
              kubernetes_resource: {
                namespace: 'production',
                kind: 'deployment',
                name: 'nginx-ingress',
                container_name: 'nginx',
                agent_id: cluster_agent.id.to_s
              },
              dependency: {
                package: {
                  name: 'libc'
                },
                version: 'v1.2.3'
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
            vendor: {
              name: 'GitLab'
            }
          }
        }
      end

      it 'returns ok when a vulnerability is created' do
        send_request(params: payload)

        expect(response).to have_gitlab_http_status(:ok)
        expect(Vulnerability.count).to eq(1)
        expect(Vulnerability.all.first.finding.name).to eq(payload[:vulnerability][:name])
      end

      it 'accepts the same payload twice' do
        send_request(params: payload)
        send_request(params: payload)

        expect(response).to have_gitlab_http_status(:ok)
        expect(Vulnerability.count).to eq(1)
        expect(json_response).to match("uuid" => Vulnerability.last.finding.uuid)
      end

      it "responds with the created vulnerability's UUID" do
        send_request(params: payload)

        expect(json_response).to match("uuid" => Vulnerability.last.finding.uuid)
      end

      context 'when payload is invalid' do
        let(:payload) { { vulnerability: 'invalid' } }

        it 'returns bad request' do
          send_request(params: payload)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when required parameters are missing' do
        where(:missing_param) { %i[vulnerability scanner] }

        with_them do
          it 'returns bad request' do
            send_request(params: payload.delete(missing_param))

            expect(response).to have_gitlab_http_status(:bad_request)
          end
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

  describe 'POST /internal/kubernetes/modules/starboard_vulnerability/scan_result' do
    let(:method) { :post }
    let(:api_url) { '/internal/kubernetes/modules/starboard_vulnerability/scan_result' }

    let_it_be(:agent_token) { create(:cluster_agent_token) }
    let_it_be(:agent) { agent_token.agent }
    let_it_be(:project) { agent.project }

    let_it_be(:existing_vulnerabilities) { create_list(:vulnerability, 4, :detected, :with_cluster_image_scanning_finding, agent_id: agent.id.to_s, project: project, report_type: :cluster_image_scanning) }
    let_it_be(:detected_vulnerabilities) { existing_vulnerabilities.first(2) }
    let_it_be(:undetected_vulnerabilities) { existing_vulnerabilities - detected_vulnerabilities }
    let_it_be(:payload) { { uuids: detected_vulnerabilities.map { |vuln| vuln.finding.uuid } } }

    include_examples 'authorization'
    include_examples 'agent authentication'

    subject { send_request(params: payload) }

    context 'is authenticated for an agent' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      before_all do
        project.add_maintainer(agent.created_by_user)
      end

      it 'returns ok' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'resolves undetected vulnerabilities' do
        subject

        expect(Vulnerability.resolved).to match_array(undetected_vulnerabilities)
      end

      it 'marks undetected vulnerabilities as resolved on default branch' do
        subject

        expect(Vulnerability.with_resolution).to match_array(undetected_vulnerabilities)
      end

      it 'does not resolve vulnerabilities with other report types' do
        Vulnerability.where(id: undetected_vulnerabilities).update_all(report_type: :container_scanning)

        expect { subject }.not_to change { Vulnerability.resolved.count }
      end

      it "does not resolve other projects' vulnerabilities" do
        Vulnerability.where(id: undetected_vulnerabilities).update_all(project_id: create(:project).id)

        expect { subject }.not_to change { Vulnerability.resolved.count }
      end

      context 'when payload is invalid' do
        let(:payload) { { uuids: -1 } }

        it 'returns bad request' do
          subject

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when feature is not available' do
        before do
          stub_licensed_features(security_dashboard: false)
        end

        it 'returns forbidden for non licensed project' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'GET /internal/kubernetes/modules/starboard_vulnerability/policies_configuration' do
    def send_request(headers: {})
      get api('/internal/kubernetes/modules/starboard_vulnerability/policies_configuration'), headers: headers.reverse_merge(jwt_auth_headers)
    end

    let_it_be(:agent_token) { create(:cluster_agent_token) }

    include_examples 'authorization'
    include_examples 'agent authentication'

    shared_examples 'agent token tracking'

    context 'when security_orchestration_policies is not licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: false)
      end

      it 'returns 402' do
        send_request(headers: { 'Authorization' => "Bearer #{agent_token.token}" })

        expect(response).to have_gitlab_http_status(:payment_required)
      end
    end

    context 'when security_orchestration_policies is licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      context 'when policies are present' do
        let(:policy) { build(:scan_execution_policy, :with_schedule_and_agent, agent: agent) }
        let(:policy_yaml) { build(:orchestration_policy_yaml, scan_execution_policy: [policy]) }
        let(:policy_management_project) do
          create(
            :project, :custom_repo, :public,
            namespace: project.namespace,
            files: {
              '.gitlab/security-policies/policy.yml' => policy_yaml
            })
        end

        let!(:policy_configuration) do
          create(
            :security_orchestration_policy_configuration,
            security_policy_management_project: policy_management_project,
            project: project
          )
        end

        it 'returns expected data', :aggregate_failures do
          send_request(headers: { 'Authorization' => "Bearer #{agent_token.token}" })

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['configurations']).to match_array(
            [
              {
                "cadence" => '30 2 * * *',
                "namespaces" => %w[namespace-a namespace-b],
                "updated_at" => policy_configuration.policy_last_updated_at.to_datetime.to_s
              }
            ])
        end
      end

      context 'when policies are empty' do
        it 'returns empty array', :aggregate_failures do
          send_request(headers: { 'Authorization' => "Bearer #{agent_token.token}" })

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['configurations']).to be_empty
        end
      end
    end
  end
end
