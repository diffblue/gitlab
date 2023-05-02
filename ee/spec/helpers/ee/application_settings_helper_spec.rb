# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::ApplicationSettingsHelper do
  describe '.visible_attributes' do
    it 'contains personal access token parameters' do
      expect(visible_attributes).to include(*%i(max_personal_access_token_lifetime))
    end

    context 'with dashboard limits' do
      let(:params) do
        %i[dashboard_limit_enabled dashboard_limit dashboard_notification_limit dashboard_notification_limit
           dashboard_limit_new_namespace_creation_enforcement_date]
      end

      context 'when on GitLab.com', :saas do
        it 'contains the dashboard limit parameters' do
          expect(helper.visible_attributes).to include(*params)
        end
      end

      context 'when not on GitLab.com' do
        it 'does not contain the dashboard limit parameters' do
          expect(helper.visible_attributes).not_to include(*params)
        end
      end
    end

    it 'contains telesign values' do
      expect(visible_attributes).to include(*%i(telesign_customer_xid telesign_api_key))
    end

    it 'contains openai_api_key value' do
      expect(visible_attributes).to include(*%i(openai_api_key))
    end
  end

  describe '.registration_features_can_be_prompted?' do
    subject { helper.registration_features_can_be_prompted? }

    context 'without a valid license' do
      before do
        allow(License).to receive(:current).and_return(nil)
      end

      context 'when service ping is enabled' do
        before do
          stub_application_setting(usage_ping_enabled: true)
        end

        it { is_expected.to be_falsey }
      end

      context 'when service ping is disabled' do
        before do
          stub_application_setting(usage_ping_enabled: false)
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'with a license' do
      let(:license) { build(:license) }

      before do
        allow(License).to receive(:current).and_return(license)
      end

      it { is_expected.to be_falsey }

      context 'when service ping is disabled' do
        before do
          stub_application_setting(usage_ping_enabled: false)
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '.deletion_protection_data' do
    let_it_be(:application_setting) { build(:application_setting) }

    before do
      application_setting.deletion_adjourned_period = 1
      application_setting.delayed_group_deletion = false
      application_setting.delayed_project_deletion = false

      helper.instance_variable_set(:@application_setting, application_setting)
    end

    subject { helper.deletion_protection_data }

    it { is_expected.to eq({ deletion_adjourned_period: 1, delayed_group_deletion: 'false', delayed_project_deletion: 'false' }) }
  end

  describe '.git_abuse_rate_limit_data', feature_category: :insider_threat do
    let_it_be(:application_setting) { build(:application_setting) }

    before do
      application_setting.max_number_of_repository_downloads = 1
      application_setting.max_number_of_repository_downloads_within_time_period = 2
      application_setting.git_rate_limit_users_allowlist = %w[username1 username2]
      application_setting.git_rate_limit_users_alertlist = [3, 4]
      application_setting.auto_ban_user_on_excessive_projects_download = true

      helper.instance_variable_set(:@application_setting, application_setting)
    end

    subject { helper.git_abuse_rate_limit_data }

    it 'returns the expected data' do
      is_expected.to eq({ max_number_of_repository_downloads: 1,
                          max_number_of_repository_downloads_within_time_period: 2,
                          git_rate_limit_users_allowlist: %w[username1 username2],
                          git_rate_limit_users_alertlist: [3, 4],
                          auto_ban_user_on_excessive_projects_download: 'true' })
    end
  end

  describe '#sync_purl_types_checkboxes', feature_category: :software_composition_analysis do
    let_it_be(:application_setting) { build(:application_setting) }

    before do
      application_setting.package_metadata_purl_types = [1, 5]

      helper.instance_variable_set(:@application_setting, application_setting)
    end

    it 'returns correctly checked purl type checkboxes' do
      helper.gitlab_ui_form_for(application_setting, url: '/admin/application_settings/security_and_compliance') do |form|
        result = helper.sync_purl_types_checkboxes(form)

        expect(result[0]).to have_checked_field('composer', with: 1)
        expect(result[1]).to have_unchecked_field('conan', with: 2)
        expect(result[2]).to have_unchecked_field('gem', with: 3)
        expect(result[3]).to have_unchecked_field('golang', with: 4)
        expect(result[4]).to have_checked_field('maven', with: 5)
        expect(result[5]).to have_unchecked_field('npm', with: 6)
        expect(result[6]).to have_unchecked_field('nuget', with: 7)
        expect(result[7]).to have_unchecked_field('pypi', with: 8)
        expect(result[8]).to have_unchecked_field('apk', with: 9)
        expect(result[9]).to have_unchecked_field('rpm', with: 10)
        expect(result[10]).to have_unchecked_field('deb', with: 11)
        expect(result[11]).to have_unchecked_field('cbl_mariner', with: 12)
      end
    end
  end
end
