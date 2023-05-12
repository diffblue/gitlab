# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ApplicationSettingsController do
  include StubENV

  let(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe 'PUT #update', feature_category: :shared do
    before do
      sign_in(admin)
    end

    it 'updates the EE specific application settings' do
      settings = {
        help_text: 'help_text',
        repository_size_limit: 1024,
        shared_runners_minutes: 60,
        geo_status_timeout: 30,
        check_namespace_plan: true,
        authorized_keys_enabled: true,
        allow_group_owners_to_manage_ldap: false,
        lock_memberships_to_ldap: true,
        geo_node_allowed_ips: '0.0.0.0/0, ::/0'
      }

      put :update, params: { application_setting: settings }

      expect(response).to redirect_to(general_admin_application_settings_path)

      settings.except(:repository_size_limit).each do |setting, value|
        expect(ApplicationSetting.current.public_send(setting)).to eq(value)
      end

      expect(ApplicationSetting.current.repository_size_limit).to eq(settings[:repository_size_limit].megabytes)
    end

    shared_examples 'settings for licensed features' do
      it 'does not update settings when licensed feature is not available' do
        stub_licensed_features(feature => false)
        attribute_names = settings.keys.map(&:to_s)

        expect { put :update, params: { application_setting: settings } }
          .not_to change { ApplicationSetting.current.reload.attributes.slice(*attribute_names) }
      end

      it 'updates settings when the feature is available' do
        stub_licensed_features(feature => true)

        put :update, params: { application_setting: settings }

        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end
    end

    shared_examples 'settings for registration features' do
      it 'does not update settings when registration features are not available' do
        stub_application_setting(usage_ping_features_enabled: false)

        attribute_names = settings.keys.map(&:to_s)

        expect { put :update, params: { application_setting: settings } }
          .not_to change { ApplicationSetting.current.reload.attributes.slice(*attribute_names) }
      end

      it 'updates settings when the registration features are available' do
        stub_application_setting(usage_ping_features_enabled: true)

        put :update, params: { application_setting: settings }

        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end
    end

    context 'mirror settings' do
      let(:settings) do
        {
          mirror_max_delay: (Gitlab::Mirror.min_delay_upper_bound / 60) + 1,
          mirror_max_capacity: 200,
          mirror_capacity_threshold: 2
        }
      end

      let(:feature) { :repository_mirrors }

      it_behaves_like 'settings for licensed features'
    end

    context 'default project deletion protection' do
      let(:settings) { { default_project_deletion_protection: true } }
      let(:feature) { :default_project_deletion_protection }

      it_behaves_like 'settings for licensed features'
    end

    context 'when `always_perform_delayed_deletion` is disabled' do
      before do
        stub_feature_flags(always_perform_delayed_deletion: false)
      end

      context 'default delayed group deletion' do
        let(:settings) { { delayed_group_deletion: true } }
        let(:feature) { :adjourned_deletion_for_projects_and_groups }

        it_behaves_like 'settings for licensed features'
      end

      context 'default delayed project deletion' do
        let(:settings) { { delayed_project_deletion: true } }
        let(:feature) { :adjourned_deletion_for_projects_and_groups }

        it_behaves_like 'settings for licensed features'
      end
    end

    context 'updating name disabled for users setting' do
      let(:settings) { { updating_name_disabled_for_users: true } }
      let(:feature) { :disable_name_update_for_users }

      it_behaves_like 'settings for licensed features'
    end

    context 'updating `group_owners_can_manage_default_branch_protection` setting' do
      let(:settings) { { group_owners_can_manage_default_branch_protection: false } }
      let(:feature) { :default_branch_protection_restriction_in_groups }

      it_behaves_like 'settings for licensed features'
    end

    context 'updating maven packages request forwarding setting' do
      let(:settings) { { maven_package_requests_forwarding: true } }
      let(:feature) { :package_forwarding }

      it_behaves_like 'settings for licensed features'
    end

    context 'updating npm packages request forwarding setting' do
      let(:settings) { { npm_package_requests_forwarding: true } }
      let(:feature) { :package_forwarding }

      it_behaves_like 'settings for licensed features'
    end

    context 'updating password complexity settings' do
      let(:settings) do
        { password_number_required: true,
          password_symbol_required: true,
          password_uppercase_required: true,
          password_lowercase_required: true }
      end

      let(:feature) { :password_complexity }

      it_behaves_like 'settings for licensed features'
      it_behaves_like 'settings for registration features'
    end

    context 'updating pypi packages request forwarding setting' do
      let(:settings) { { pypi_package_requests_forwarding: true } }
      let(:feature) { :package_forwarding }

      it_behaves_like 'settings for licensed features'
    end

    context 'updating `git_two_factor_session_expiry` setting' do
      before do
        stub_feature_flags(two_factor_for_cli: true)
      end

      let(:settings) { { git_two_factor_session_expiry: 10 } }
      let(:feature) { :git_two_factor_enforcement }

      it_behaves_like 'settings for licensed features'
    end

    context 'updating maintenance mode setting' do
      let(:settings) do
        {
          maintenance_mode: true,
          maintenance_mode_message: 'GitLab is in maintenance'
        }
      end

      let(:feature) { :geo }

      it_behaves_like 'settings for licensed features'
      it_behaves_like 'settings for registration features'
    end

    context 'deletion adjourned period' do
      let(:settings) { { deletion_adjourned_period: 6 } }
      let(:feature) { :adjourned_deletion_for_projects_and_groups }

      it_behaves_like 'settings for licensed features'
    end

    context 'additional email footer' do
      let(:settings) { { email_additional_text: 'scary legal footer' } }
      let(:feature) { :email_additional_text }

      it_behaves_like 'settings for licensed features'
    end

    context 'custom project templates settings' do
      let(:group) { create(:group) }
      let(:settings) { { custom_project_templates_group_id: group.id } }
      let(:feature) { :custom_project_templates }

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

    context 'globally allowed IPs' do
      let(:settings) { { globally_allowed_ips: '10.0.0.0/8, 192.168.1.0/24' } }
      let(:feature) { :group_ip_restriction }

      it_behaves_like 'settings for licensed features'
    end

    context 'required instance ci template' do
      let(:settings) { { required_instance_ci_template: 'Auto-DevOps' } }
      let(:feature) { :required_ci_templates }

      it_behaves_like 'settings for licensed features'

      context 'when ApplicationSetting already has a required_instance_ci_template value' do
        before do
          ApplicationSetting.current.update!(required_instance_ci_template: 'Auto-DevOps')
        end

        context 'with a valid value' do
          let(:settings) { { required_instance_ci_template: 'Code-Quality' } }

          it_behaves_like 'settings for licensed features'
        end

        context 'with an empty value' do
          it 'sets required_instance_ci_template as nil' do
            stub_licensed_features(required_ci_templates: true)

            put :update, params: { application_setting: { required_instance_ci_template: '' } }

            expect(ApplicationSetting.current.required_instance_ci_template).to be_nil
          end
        end

        context 'without key' do
          it 'does not set required_instance_ci_template to nil' do
            put :update, params: { application_setting: {} }

            expect(ApplicationSetting.current.required_instance_ci_template).to be == 'Auto-DevOps'
          end
        end
      end
    end

    it 'updates repository_size_limit' do
      put :update, params: { application_setting: { repository_size_limit: '100' } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(controller).to set_flash[:notice].to('Application settings saved successfully')
    end

    it 'does not accept negative repository_size_limit' do
      put :update, params: { application_setting: { repository_size_limit: '-100' } }

      expect(response).to render_template(:general)
      expect(assigns(:application_setting).errors[:repository_size_limit]).to be_present
    end

    it 'does not accept invalid repository_size_limit' do
      put :update, params: { application_setting: { repository_size_limit: 'one thousand' } }

      expect(response).to render_template(:general)
      expect(assigns(:application_setting).errors[:repository_size_limit]).to be_present
    end

    it 'does not accept empty repository_size_limit' do
      put :update, params: { application_setting: { repository_size_limit: '' } }

      expect(response).to render_template(:general)
      expect(assigns(:application_setting).errors[:repository_size_limit]).to be_present
    end

    describe 'verify panel actions' do
      Admin::ApplicationSettingsController::EE_VALID_SETTING_PANELS.each do |valid_action|
        it_behaves_like 'renders correct panels' do
          let(:action) { valid_action }
        end
      end
    end

    context 'maintenance mode settings' do
      let(:message) { 'Maintenance mode is on.' }

      before do
        stub_licensed_features(geo: true)
      end

      it "updates maintenance_mode setting" do
        put :update, params: { application_setting: { maintenance_mode: true } }

        expect(response).to redirect_to(general_admin_application_settings_path)
        expect(ApplicationSetting.current.maintenance_mode).to be_truthy
      end

      it "updates maintenance_mode_message setting" do
        put :update, params: { application_setting: { maintenance_mode_message: message } }

        expect(response).to redirect_to(general_admin_application_settings_path)
        expect(ApplicationSetting.current.maintenance_mode_message).to eq(message)
      end

      context 'when update disables maintenance mode' do
        it 'removes maintenance_mode_message setting' do
          put :update, params: { application_setting: { maintenance_mode: false } }

          expect(response).to redirect_to(general_admin_application_settings_path)
          expect(ApplicationSetting.current.maintenance_mode).to be_falsy
          expect(ApplicationSetting.current.maintenance_mode_message).to be_nil
        end
      end

      context 'when update does not disable maintenance mode' do
        it 'does not remove maintenance_mode_message' do
          set_maintenance_mode(message)

          put :update, params: { application_setting: {} }

          expect(ApplicationSetting.current.maintenance_mode_message).to eq(message)
        end
      end

      context 'when updating maintenance_mode_message with empty string' do
        it 'removes maintenance_mode_message' do
          set_maintenance_mode(message)

          put :update, params: { application_setting: { maintenance_mode_message: '' } }

          expect(ApplicationSetting.current.maintenance_mode_message).to eq(nil)
        end
      end
    end
  end

  describe '#advanced_search', feature_category: :global_search do
    before do
      sign_in(admin)
      @request.env['HTTP_REFERER'] = advanced_search_admin_application_settings_path
    end

    context 'check search version is compatability' do
      let_it_be(:helper) { ::Gitlab::Elastic::Helper.default }

      before do
        allow(::Gitlab::Elastic::Helper).to receive(:default).and_return(helper)
      end

      it 'does not alert when version is compatible' do
        allow(helper).to receive(:supported_version?).and_return(true)

        get :advanced_search
        expect(assigns[:search_error_if_version_incompatible]).to be_falsey
      end

      it 'alerts when version is incompatible' do
        allow(::Gitlab::Elastic::Helper.default).to receive(:supported_version?).and_return(false)

        get :advanced_search
        expect(assigns[:search_error_if_version_incompatible]).to be_truthy
      end
    end

    context 'warning if not using index aliases' do
      let_it_be(:helper) { ::Gitlab::Elastic::Helper.default }

      before do
        allow(::Gitlab::Elastic::Helper).to receive(:default).and_return(helper)
      end

      it 'warns when NOT using index aliases' do
        allow(helper).to receive(:alias_missing?).and_return true
        get :advanced_search
        expect(assigns[:elasticsearch_warn_if_not_using_aliases]).to be_truthy
      end

      it 'does NOT warn when using index aliases' do
        allow(helper).to receive(:alias_missing?).and_return false
        get :advanced_search
        expect(assigns[:elasticsearch_warn_if_not_using_aliases]).to be_falsy
      end

      it 'does NOT blow up if elasticsearch is unreachable' do
        allow(helper).to receive(:alias_missing?).and_raise(::Elasticsearch::Transport::Transport::ServerError, 'boom')
        get :advanced_search
        expect(assigns[:elasticsearch_warn_if_not_using_aliases]).to be_falsy
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'warning outdated code search mappings' do
      let_it_be(:helper) { ::Gitlab::Elastic::Helper.default }

      before do
        allow(::Gitlab::Elastic::Helper).to receive(:default).and_return(helper)
      end

      it 'warns when outdated code mappings are used' do
        allow(helper).to receive(:get_meta).and_return('created_by' => '15.4.9')
        get :advanced_search
        expect(assigns[:search_outdated_code_analyzer_detected]).to be_truthy
      end

      it 'warns when meta field is not present' do
        allow(helper).to receive(:get_meta).and_return(nil)
        get :advanced_search
        expect(assigns[:search_outdated_code_analyzer_detected]).to be_truthy
      end

      it 'does NOT warn when using new mappings' do
        allow(helper).to receive(:get_meta).and_return('created_by' => '15.5.0')
        get :advanced_search
        expect(assigns[:search_outdated_code_analyzer_detected]).to be_falsey
      end

      it 'does NOT blow up if elasticsearch is unreachable' do
        allow(helper).to receive(:get_meta).and_raise(::Elasticsearch::Transport::Transport::ServerError, 'boom')
        get :advanced_search
        expect(assigns[:search_outdated_code_analyzer_detected]).to be_falsey
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'advanced search settings' do
      it 'updates the advanced search settings' do
        settings = {
            elasticsearch_url: URI.parse('http://my-elastic.search:9200'),
            elasticsearch_indexing: false,
            elasticsearch_aws: true,
            elasticsearch_aws_access_key: 'elasticsearch_aws_access_key',
            elasticsearch_aws_secret_access_key: 'elasticsearch_aws_secret_access_key',
            elasticsearch_aws_region: 'elasticsearch_aws_region',
            elasticsearch_search: true
        }

        patch :advanced_search, params: { application_setting: settings }

        expect(response).to redirect_to(advanced_search_admin_application_settings_path)
        settings.except(:elasticsearch_url).each do |setting, value|
          expect(ApplicationSetting.current.public_send(setting)).to eq(value)
        end
        expect(ApplicationSetting.current.elasticsearch_url).to contain_exactly(settings[:elasticsearch_url])
      end
    end

    context 'zero-downtime elasticsearch reindexing' do
      render_views

      let!(:task) { create(:elastic_reindexing_task) }

      it 'assigns last elasticsearch reindexing task' do
        get :advanced_search

        expect(assigns(:last_elasticsearch_reindexing_task)).to eq(task)
        expect(response.body).to include("Reindexing Status: #{task.state}")
      end
    end

    context 'elasticsearch_aws_secret_access_key setting is blank' do
      let(:settings) do
        {
          elasticsearch_aws_access_key: 'elasticsearch_aws_access_key',
          elasticsearch_aws_secret_access_key: ''
        }
      end

      it 'does not update the elasticsearch_aws_secret_access_key setting' do
        expect { patch :advanced_search, params: { application_setting: settings } }
          .not_to change { ApplicationSetting.current.reload.elasticsearch_aws_secret_access_key }
      end
    end
  end

  describe 'GET #seat_link_payload', feature_category: :sm_provisioning do
    context 'when a non-admin user attempts a request' do
      before do
        sign_in(create(:user))
      end

      it 'returns a 404 response' do
        get :seat_link_payload, format: :html

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when an admin user attempts a request' do
      let_it_be(:yesterday) { Time.current.utc.yesterday }
      let_it_be(:max_count) { 15 }
      let_it_be(:current_count) { 10 }

      around do |example|
        freeze_time { example.run }
      end

      before_all do
        create(:historical_data, recorded_at: yesterday - 1.day, active_user_count: max_count)
        create(:historical_data, recorded_at: yesterday, active_user_count: current_count)
      end

      before do
        sign_in(admin)
      end

      it 'returns HTML data', :aggregate_failures do
        get :seat_link_payload, format: :html

        expect(response).to have_gitlab_http_status(:ok)

        body = response.body
        expect(body).to start_with('<span id="LC1" class="line" lang="json">')
        expect(body).to include('<span class="nl">"license_key"</span>')
        expect(body).to include("<span class=\"s2\">\"#{yesterday.iso8601}\"</span>")
        expect(body).to include("<span class=\"mi\">#{max_count}</span>")
        expect(body).to include("<span class=\"mi\">#{current_count}</span>")
      end

      it 'returns JSON data', :aggregate_failures do
        get :seat_link_payload, format: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(Gitlab::SeatLinkData.new.to_json)
      end
    end
  end

  def set_maintenance_mode(message)
    ApplicationSetting.current.update!(
      maintenance_mode: true,
      maintenance_mode_message: message
    )
  end
end
