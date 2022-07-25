# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Security::PoliciesController, type: :request do
  let_it_be(:owner) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:policy_management_project) { create(:project, :repository, namespace: group) }
  let_it_be(:policy) { build(:scan_execution_policy) }
  let_it_be(:policy_configuration) do
    create(:security_orchestration_policy_configuration, :namespace,
      security_policy_management_project: policy_management_project,
      namespace: group
    )
  end

  describe 'GET #edit' do
    let(:policy_id) { policy[:name] }
    let(:policy_type) { 'scan_execution_policy' }
    let(:edit) { edit_group_security_policy_url(group, id: policy_id, type: policy_type) }

    before do
      group.add_developer(user)
      sign_in(user)
    end

    context 'with authorized user' do
      context 'when feature is licensed' do
        before do
          stub_licensed_features(security_orchestration_policies: true)
        end

        context 'when feature is disabled' do
          before do
            stub_feature_flags(group_level_security_policies: false)
          end

          it 'returns 404' do
            get edit

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when feature is enabled' do
          before do
            stub_feature_flags(group_level_security_policies: true)
            allow_next_instance_of(Repository) do |repository|
              allow(repository).to receive(:blob_data_at).and_return({ scan_execution_policy: [policy] }.to_yaml)
            end
          end

          it 'renders the edit page', :aggregate_failures do
            get edit

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:edit)

            app = Nokogiri::HTML.parse(response.body).at_css('div#js-group-policy-builder-app')

            expect(app.attributes['data-policy'].value).to eq(policy.to_json)
            expect(app.attributes['data-policy-type'].value).to eq('scan_execution_policy')
            expect(app.attributes['data-assigned-policy-project'].value).to eq({
              id: policy_management_project.to_gid.to_s,
              name: policy_management_project.name,
              full_path: policy_management_project.full_path,
              branch: policy_management_project.default_branch_or_main
            }.to_json)
            expect(app.attributes['data-disable-scan-policy-update'].value).to eq('true')
            expect(app.attributes['data-policies-path'].value).to eq(
              "/groups/#{group.full_path}/-/security/policies"
            )
            expect(app.attributes['data-scan-policy-documentation-path'].value).to eq(
              '/help/user/application_security/policies/index'
            )
            expect(app.attributes['data-namespace-path'].value).to eq(group.full_path)
            expect(app.attributes['data-namespace-id'].value).to eq(group.id.to_s)
          end

          context 'when type is missing' do
            let(:policy_type) { nil }

            it 'redirects to #index', :aggregate_failures do
              get edit

              expect(response).to redirect_to(group_security_policies_path(group))
              expect(flash[:alert]).to eq(_('type parameter is missing and is required'))
            end
          end

          context 'when type is invalid' do
            let(:policy_type) { 'invalid' }

            it 'redirects to #index', :aggregate_failures do
              get edit

              expect(response).to redirect_to(group_security_policies_path(group))
              expect(flash[:alert]).to eq(_('Invalid policy type'))
            end
          end

          context 'when id does not exist' do
            let(:policy_id) { 'no-policy' }

            it 'returns 404' do
              get edit

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          context 'when there is no policy configuration' do
            let_it_be(:group) { create(:group) }
            let_it_be(:policy_configuration) { nil }

            it 'redirects to #index', :aggregate_failures do
              get edit

              expect(response).to redirect_to(group_security_policies_path(group))
              expect(flash[:alert]).to eq(_('Project does not have a policy configuration'))
            end
          end

          context 'when policy yaml file does not exist' do
            before do
              allow_next_instance_of(Repository) do |repository|
                allow(repository).to receive(:blob_data_at).and_return({}.to_yaml)
              end
            end

            it 'redirects to project page', :aggregate_failures do
              get edit

              expect(response).to redirect_to(project_path(policy_management_project))
              expect(flash[:alert]).to eq(_("Policy management project does not have any policies in %{policy_path}" % {
                policy_path: ::Security::OrchestrationPolicyConfiguration::POLICY_PATH
              }))
            end
          end

          context 'when policy yaml is invalid' do
            let_it_be(:policy) { { name: 'invalid' } }

            it 'redirects to policy file', :aggregate_failures do
              get edit

              expect(flash[:alert]).to eq(_('Could not fetch policy because existing policy YAML is invalid'))
              expect(response).to redirect_to(
                project_blob_path(
                  policy_management_project,
                  File.join(
                    policy_management_project.default_branch,
                    ::Security::OrchestrationPolicyConfiguration::POLICY_PATH
                  )
                )
              )
            end
          end
        end
      end

      context 'when feature is not licensed' do
        before do
          stub_licensed_features(security_orchestration_policies: false)
        end

        it 'returns 404' do
          get edit

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with unauthorized user' do
      before do
        group.add_reporter(user)
        stub_licensed_features(security_orchestration_policies: true)
        sign_in(user)
      end

      it 'returns 404' do
        get edit

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with anonymous user' do
      before do
        sign_out(user)
      end

      it 'returns 404' do
        get edit

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #index' do
    using RSpec::Parameterized::TableSyntax

    where(:user_role, :license, :feature, :status) do
      :reporter   | true  | true  | :not_found
      :developer  | true  | false | :not_found
      :developer  | false | true  | :not_found
      :developer  | false | false | :not_found
      :developer  | true  | true  | :ok
    end

    subject(:request) { get index, params: { namespace_id: group } }

    let(:index) { group_security_policies_url(group) }

    with_them do
      before do
        group.public_send("add_#{user_role}", user)
        sign_in(user)
        stub_licensed_features(security_orchestration_policies: license)
        stub_feature_flags(group_level_security_policies: feature)
      end

      specify do
        subject

        expect(response).to have_gitlab_http_status(status)
      end
    end
  end

  describe 'GET #schema' do
    let(:schema) { schema_group_security_policies_url(group) }
    let(:expected_json) do
      Gitlab::Json.parse(
        File.read(
          Rails.root.join(
            Security::OrchestrationPolicyConfiguration::POLICY_SCHEMA_PATH
          )
        )
      )
    end

    before do
      group.add_developer(user)
      sign_in(user)
      stub_licensed_features(security_orchestration_policies: true)
      stub_feature_flags(group_level_security_policies: true)
    end

    it 'returns JSON schema' do
      get schema

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(expected_json)
    end
  end
end
