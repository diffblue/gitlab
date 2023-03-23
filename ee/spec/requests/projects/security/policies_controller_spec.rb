# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::PoliciesController, type: :request, feature_category: :security_policy_management do
  let_it_be(:owner) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, namespace: owner.namespace) }
  let_it_be(:policy_management_project) { create(:project, :repository, namespace: owner.namespace) }
  let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration, security_policy_management_project: policy_management_project, project: project) }
  let_it_be(:policy) { build(:scan_execution_policy) }
  let_it_be(:type) { 'scan_execution_policy' }
  let_it_be(:index) { project_security_policies_url(project) }
  let_it_be(:new) { new_project_security_policy_url(project) }
  let_it_be(:feature_enabled) { true }

  let(:edit) { edit_project_security_policy_url(project, id: policy[:name], type: type) }

  before do
    project.add_developer(user)
    policy_management_project.add_developer(user)
    sign_in(user)
    stub_licensed_features(security_orchestration_policies: feature_enabled)
    allow_next_instance_of(Repository) do |repository|
      allow(repository).to receive(:blob_data_at).and_return({ scan_execution_policy: [policy] }.to_yaml)
    end
  end

  describe 'GET #edit' do
    context 'with authorized user' do
      context 'when feature is available' do
        it 'renders the edit page' do
          get edit

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:edit)

          app = Nokogiri::HTML.parse(response.body).at_css('div#js-policy-builder-app')

          expect(app.attributes['data-policy'].value).to eq(policy.to_json)
          expect(app.attributes['data-policy-type'].value).to eq(type)
        end

        it 'does not contain any approver data' do
          get edit
          app = Nokogiri::HTML.parse(response.body).at_css('div#js-policy-builder-app')

          expect(app['data-scan-result-approvers']).to be_nil
        end

        context 'with scan result policy type' do
          let_it_be(:type) { 'scan_result_policy' }
          let_it_be(:policy) { build(:scan_result_policy) }
          let_it_be(:group) { create(:group) }
          let_it_be(:service_result) { { users: [user], groups: [group], roles: ['OWNER'], status: :success } }

          let(:service) { instance_double('::Security::SecurityOrchestrationPolicies::FetchPolicyApproversService', execute: service_result) }

          before do
            allow_next_instance_of(Repository) do |repository|
              allow(repository).to receive(:blob_data_at).and_return({ scan_result_policy: [policy] }.to_yaml)
            end
            allow(::Security::SecurityOrchestrationPolicies::FetchPolicyApproversService).to receive(:new).with(policy: policy, container: project, current_user: user).and_return(service)
          end

          it 'renders the edit page with approvers data' do
            get edit

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:edit)

            app = Nokogiri::HTML.parse(response.body).at_css('div#js-policy-builder-app')

            expect(app['data-policy']).to eq(policy.to_json)
            expect(app['data-policy-type']).to eq(type)
            expect(app['data-scan-result-approvers']).to include(user.name, user.id.to_s, group.full_path, group.id.to_s)
          end
        end

        context 'when type is missing' do
          let_it_be(:edit) { edit_project_security_policy_url(project, id: policy[:name]) }

          it 'redirects to #index' do
            get edit

            expect(response).to redirect_to(project_security_policies_path(project))
          end
        end

        context 'when type is invalid' do
          let_it_be(:edit) { edit_project_security_policy_url(project, id: policy[:name], type: 'invalid') }

          it 'redirects to #index' do
            get edit

            expect(response).to redirect_to(project_security_policies_path(project))
          end
        end

        context 'when id does not exist' do
          let_it_be(:edit) { edit_project_security_policy_url(project, id: 'no-existing-policy', type: type) }

          it 'returns 404' do
            get edit

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when there is no policy configuration' do
          let_it_be(:project) { create(:project, namespace: owner.namespace) }
          let_it_be(:policy_configuration) { nil }
          let_it_be(:edit) { edit_project_security_policy_url(project, id: policy[:name], type: type) }

          it 'returns 404' do
            get edit

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when policy yaml file does not exist' do
          before do
            allow_next_instance_of(Repository) do |repository|
              allow(repository).to receive(:blob_data_at).and_return({}.to_yaml)
            end
          end

          it 'redirects to project page' do
            get edit

            expect(response).to redirect_to(project_path(policy_management_project))
          end
        end

        context 'when policy yaml is invalid' do
          let_it_be(:policy) { { name: 'invalid' } }

          it 'redirects to policy file' do
            get edit

            expect(response).to redirect_to(
              project_blob_path(
                policy_management_project,
                File.join(policy_management_project.default_branch, ::Security::OrchestrationPolicyConfiguration::POLICY_PATH)
              )
            )
          end
        end
      end

      context 'when feature is not available' do
        let_it_be(:feature_enabled) { false }

        it 'returns 404' do
          get edit

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with unauthorized user' do
      before do
        project.add_guest(user)
        sign_in(user)
      end

      context 'when feature is available' do
        let_it_be(:feature_enabled) { true }

        it 'returns 404' do
          get edit

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with anonymous user' do
      before do
        sign_out(user)
      end

      it 'returns 302' do
        get edit

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #new' do
    using RSpec::Parameterized::TableSyntax

    where(:license, :status) do
      true | :ok
      false | :not_found
    end

    subject(:request) { get new, params: { namespace_id: project.namespace, project_id: project } }

    with_them do
      before do
        stub_licensed_features(security_orchestration_policies: license)
      end

      specify do
        subject

        expect(response).to have_gitlab_http_status(status)
      end
    end
  end

  describe 'GET #index' do
    using RSpec::Parameterized::TableSyntax

    where(:license, :status) do
      true | :ok
      false | :not_found
    end

    subject(:request) { get index, params: { namespace_id: project.namespace, project_id: project } }

    with_them do
      before do
        stub_licensed_features(security_orchestration_policies: license)
      end

      specify do
        subject

        expect(response).to have_gitlab_http_status(status)
      end
    end
  end

  describe 'GET #schema' do
    let(:schema) { schema_project_security_policies_url(project) }
    let(:expected_json) do
      Gitlab::Json.parse(
        File.read(
          Rails.root.join(
            Security::OrchestrationPolicyConfiguration::POLICY_SCHEMA_PATH
          )
        )
      )
    end

    it 'returns JSON schema' do
      get schema

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(expected_json)
    end
  end
end
