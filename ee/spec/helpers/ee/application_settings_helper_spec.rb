# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::ApplicationSettingsHelper do
  describe '.visible_attributes' do
    it 'contains personal access token parameters' do
      expect(visible_attributes).to include(*%i(max_personal_access_token_lifetime))
    end

    it 'contains slack app parameters' do
      params = %i(slack_app_enabled slack_app_id slack_app_secret slack_app_signing_secret slack_app_verification_token)

      expect(helper.visible_attributes).to include(*params)
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
end
