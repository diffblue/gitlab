# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Settings, 'EE Settings', :aggregate_failures, feature_category: :shared do
  include StubENV

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:project) { create(:project) }
  let(:path) { "/application/settings" }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  it_behaves_like 'GET request permissions for admin mode'

  describe "PUT /application/settings" do
    it_behaves_like 'PUT request permissions for admin mode' do
      let(:params) { { help_text: 'Help text', file_template_project_id: project.id } }
    end

    it 'sets EE specific settings' do
      stub_licensed_features(custom_file_templates: true)

      put api(path, admin, admin_mode: true),
        params: {
          help_text: 'Help text',
          file_template_project_id: project.id
        }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['help_text']).to eq('Help text')
      expect(json_response['file_template_project_id']).to eq(project.id)
    end

    context 'elasticsearch settings' do
      it 'limits namespaces and projects properly' do
        namespace_ids = create_list(:namespace, 2).map(&:id)
        project_ids = create_list(:project, 2).map(&:id)

        put api('/application/settings', admin, admin_mode: true),
            params: {
              elasticsearch_limit_indexing: true,
              elasticsearch_project_ids: project_ids.join(','),
              elasticsearch_namespace_ids: namespace_ids.join(',')
            }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['elasticsearch_limit_indexing']).to eq(true)
        expect(json_response['elasticsearch_project_ids']).to eq(project_ids)
        expect(json_response['elasticsearch_namespace_ids']).to eq(namespace_ids)
        expect(ElasticsearchIndexedNamespace.count).to eq(2)
        expect(ElasticsearchIndexedProject.count).to eq(2)
      end

      it 'removes namespaces and projects properly' do
        stub_ee_application_setting(elasticsearch_limit_indexing: true)
        create(:elasticsearch_indexed_namespace).namespace.id
        create(:elasticsearch_indexed_project).project.id

        put api('/application/settings', admin, admin_mode: true),
            params: {
              elasticsearch_namespace_ids: []
            }.to_json,
            headers: {
              'CONTENT_TYPE' => 'application/json'
            }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['elasticsearch_namespace_ids']).to eq([])
        expect(ElasticsearchIndexedNamespace.count).to eq(0)
        expect(ElasticsearchIndexedProject.count).to eq(1)
      end
    end

    context 'slack app settings' do
      it 'updates slack app settings' do
        put api('/application/settings', admin, admin_mode: true),
          params: {
            slack_app_enabled: true,
            slack_app_id: 'SLACK_APP_ID',
            slack_app_secret: 'SLACK_APP_SECRET',
            slack_app_signing_secret: 'SLACK_APP_SIGNING_SECRET',
            slack_app_verification_token: 'SLACK_APP_VERIFICATION_TOKEN'
          }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['slack_app_enabled']).to eq(true)
        expect(json_response['slack_app_id']).to eq('SLACK_APP_ID')
        expect(json_response['slack_app_secret']).to eq('SLACK_APP_SECRET')
        expect(json_response['slack_app_signing_secret']).to eq('SLACK_APP_SIGNING_SECRET')
        expect(json_response['slack_app_verification_token']).to eq('SLACK_APP_VERIFICATION_TOKEN')
      end
    end

    context 'secret_detection_token_revocation_enabled is true' do
      context 'secret_detection_token_revocation_url value is present' do
        let(:revocation_url) { 'https://example.com/secret_detection_token_revocation' }
        let(:revocation_token_types_url) { 'https://example.com/secret_detection_revocation_token_types' }
        let(:revocation_token) { 'AKDD345$%^^' }

        it 'updates secret_detection_token_revocation_url' do
          put api('/application/settings', admin, admin_mode: true),
            params: {
              secret_detection_token_revocation_enabled: true,
              secret_detection_token_revocation_url: revocation_url,
              secret_detection_token_revocation_token: revocation_token,
              secret_detection_revocation_token_types_url: revocation_token_types_url
            }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['secret_detection_token_revocation_enabled']).to be(true)
          expect(json_response['secret_detection_token_revocation_url']).to eq(revocation_url)
          expect(json_response['secret_detection_revocation_token_types_url']).to eq(revocation_token_types_url)
          expect(json_response['secret_detection_token_revocation_token']).to eq(revocation_token)
        end
      end

      context 'missing secret_detection_token_revocation_url value' do
        it 'returns a blank parameter error message' do
          put api('/application/settings', admin, admin_mode: true), params: { secret_detection_token_revocation_enabled: true }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to include('secret_detection_token_revocation_url is missing, secret_detection_revocation_token_types_url is missing')
        end
      end
    end

    context 'openai api key setting' do
      it 'updates openai_api_key' do
        put api('/application/settings', admin, admin_mode: true), params: { openai_api_key: 'OPENAI_API_KEY' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['openai_api_key']).to eq('OPENAI_API_KEY')
      end
    end
  end

  shared_examples 'settings for licensed features' do
    let(:attribute_names) { settings.keys.map(&:to_s) }

    before do
      # Make sure the settings exist before the specs
      get api(path, admin, admin_mode: true)
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(feature => false)
      end

      it 'hides the attributes in the API' do
        get api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        attribute_names.each do |attribute|
          expect(json_response.keys).not_to include(attribute)
        end
      end

      it 'does not update application settings' do
        put api(path, admin, admin_mode: true), params: settings

        expect(response).to have_gitlab_http_status(:ok)

        expect { put api(path, admin, admin_mode: true), params: settings }
          .not_to change { ApplicationSetting.current.reload.attributes.slice(*attribute_names) }
      end
    end

    context 'when the feature is available' do
      before do
        stub_licensed_features(feature => true)
      end

      it 'includes the attributes in the API' do
        get api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        attribute_names.each do |attribute|
          expect(json_response.keys).to include(attribute)
        end
      end

      it 'allows updating the settings' do
        put api(path, admin, admin_mode: true), params: settings
        expect(response).to have_gitlab_http_status(:ok)

        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end
    end
  end

  context 'mirroring settings' do
    let(:settings) { { mirror_max_capacity: 15 } }
    let(:feature) { :repository_mirrors }

    it_behaves_like 'settings for licensed features'
  end

  context 'custom email footer' do
    let(:settings) { { email_additional_text: 'this is a scary legal footer' } }
    let(:feature) { :email_additional_text }

    it_behaves_like 'settings for licensed features'
  end

  context 'git_two_factor_session_expiry setting' do
    before do
      stub_feature_flags(two_factor_for_cli: true)
    end

    let(:settings) { { git_two_factor_session_expiry: 10 } }
    let(:feature) { :git_two_factor_enforcement }

    it_behaves_like 'settings for licensed features'
  end

  context 'default project deletion protection' do
    let(:settings) { { default_project_deletion_protection: true } }
    let(:feature) { :default_project_deletion_protection }

    it_behaves_like 'settings for licensed features'
  end

  context 'default delayed group deletion' do
    let(:settings) { { delayed_group_deletion: true } }
    let(:feature) { :adjourned_deletion_for_projects_and_groups }

    context 'when `always_perform_delayed_deletion` is disabled' do
      before do
        stub_feature_flags(always_perform_delayed_deletion: false)
      end

      it_behaves_like 'settings for licensed features'
    end
  end

  context 'delayed project deletion' do
    let(:settings) { { delayed_project_deletion: true } }
    let(:feature) { :adjourned_deletion_for_projects_and_groups }

    context 'when `always_perform_delayed_deletion` is disabled' do
      before do
        stub_feature_flags(always_perform_delayed_deletion: false)
      end

      it_behaves_like 'settings for licensed features'
    end
  end

  context 'group_owners_can_manage_default_branch_protection setting' do
    let(:settings) { { group_owners_can_manage_default_branch_protection: false } }
    let(:feature) { :default_branch_protection_restriction_in_groups }

    it_behaves_like 'settings for licensed features'
  end

  context 'delayed deletion period' do
    let(:settings) { { deletion_adjourned_period: 5 } }
    let(:feature) { :adjourned_deletion_for_projects_and_groups }

    it_behaves_like 'settings for licensed features'
  end

  context 'custom file template project' do
    let(:settings) { { file_template_project_id: project.id } }
    let(:feature) { :custom_file_templates }

    it_behaves_like 'settings for licensed features'
  end

  context 'updating name disabled for users' do
    let(:settings) { { updating_name_disabled_for_users: true } }
    let(:feature) { :disable_name_update_for_users }

    it_behaves_like 'settings for licensed features'
  end

  context 'merge request approvers rules' do
    let(:settings) do
      {
        disable_overriding_approvers_per_merge_request: true,
        prevent_merge_requests_author_approval: true,
        prevent_merge_requests_committers_approval: true
      }
    end

    let(:feature) { :admin_merge_request_approvers_rules }

    it_behaves_like 'settings for licensed features'
  end

  context 'updating npm packages request forwarding' do
    let(:settings) { { npm_package_requests_forwarding: true } }
    let(:feature) { :package_forwarding }

    it_behaves_like 'settings for licensed features'
  end

  context 'maintenance mode' do
    let(:settings) do
      {
        maintenance_mode: true,
        maintenance_mode_message: 'GitLab is in maintenance'
      }
    end

    let(:feature) { :geo }

    it_behaves_like 'settings for licensed features'

    context 'when geo feature is disabled' do
      let(:attribute_names) { settings.keys.map(&:to_s) }

      context "with registration features disabled" do
        before do
          stub_application_setting(usage_ping_features_enabled: false)
        end

        it 'hides the attributes in the API' do
          get api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:ok)
          attribute_names.each do |attribute|
            expect(json_response.keys).not_to include(attribute)
          end
        end

        it 'does not update application settings' do
          put api(path, admin, admin_mode: true), params: settings

          expect(response).to have_gitlab_http_status(:ok)

          expect { put api(path, admin, admin_mode: true), params: settings }
            .not_to change { ApplicationSetting.current.reload.attributes.slice(*attribute_names) }
        end
      end

      context "with registration features enabled" do
        before do
          stub_application_setting(usage_ping_features_enabled: true)
        end

        it 'includes the attributes in the API' do
          get api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:ok)
          attribute_names.each do |attribute|
            expect(json_response.keys).to include(attribute)
          end
        end

        it 'allows updating the settings' do
          put api(path, admin, admin_mode: true), params: settings
          expect(response).to have_gitlab_http_status(:ok)

          settings.each do |attribute, value|
            expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
          end
        end
      end
    end
  end

  context 'password complexity settings' do
    let(:settings) do
      {
        password_number_required: true,
        password_symbol_required: true,
        password_uppercase_required: true,
        password_lowercase_required: true
      }
    end

    let(:feature) { :password_complexity }

    it_behaves_like 'settings for licensed features'
  end

  context 'git abuse rate limit settings', feature_category: :insider_threat do
    let(:user) { create(:user) }

    let(:settings) do
      {
        max_number_of_repository_downloads: 5,
        max_number_of_repository_downloads_within_time_period: 60,
        git_rate_limit_users_allowlist: [user.username],
        git_rate_limit_users_alertlist: [user.id],
        auto_ban_user_on_excessive_projects_download: true
      }
    end

    let(:feature) { :git_abuse_rate_limit }

    it_behaves_like 'settings for licensed features'
  end

  context 'disable personal access tokens setting' do
    let(:settings) { { disable_personal_access_tokens: false } }
    let(:feature) { :disable_personal_access_tokens }

    it_behaves_like 'settings for licensed features'
  end
end
