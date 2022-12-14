# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Licenses::SubmitLicenseUsageDataBanner do
  include ActionView::Helpers::SanitizeHelper

  let_it_be(:feature_name) { described_class::SUBMIT_LICENSE_USAGE_DATA_BANNER }

  describe '#reset' do
    using RSpec::Parameterized::TableSyntax

    subject(:reset_data) { described_class.new.reset }

    let(:check_namespace_plan) { false }
    let(:cloud_licensing_enabled) { true }
    let(:offline_cloud_licensing_enabled) { true }
    let(:trial) { false }
    let(:starts_at) { Date.current }

    def callout_count
      Users::Callout.where(feature_name: feature_name).count
    end

    shared_examples 'skips resetting the submit license usage data' do
      it 'does not reset the submit license usage data' do
        reset_data

        expect(Gitlab::CurrentSettings.reload.license_usage_data_exported).to eq(true)
        expect(callout_count).to eq(1)
      end
    end

    shared_examples 'resets the submit license usage data' do
      it 'resets the submit license usage data' do
        reset_data

        expect(Gitlab::CurrentSettings.reload.license_usage_data_exported).to eq(false)
        expect(callout_count).to eq(0)
      end
    end

    before do
      Gitlab::CurrentSettings.update!(license_usage_data_exported: true)

      create_current_license(
        {
          cloud_licensing_enabled: cloud_licensing_enabled,
          offline_cloud_licensing_enabled: offline_cloud_licensing_enabled,
          restrictions: { trial: trial },
          starts_at: starts_at
        }
      )

      create(:callout, feature_name: feature_name, dismissed_at: Time.current)

      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(check_namespace_plan)
    end

    context 'when check namespace plan setting is enabled' do
      let(:check_namespace_plan) { true }

      include_examples 'skips resetting the submit license usage data'
    end

    context 'when there is only a future dated license' do
      let(:starts_at) { Date.tomorrow }

      before do
        ::License.current.destroy!
      end

      include_examples 'skips resetting the submit license usage data'
    end

    context 'when current license is an online cloud license' do
      let(:offline_cloud_licensing_enabled) { false }

      include_examples 'skips resetting the submit license usage data'
    end

    context 'when current license is a legacy license' do
      let(:cloud_licensing_enabled) { false }
      let(:offline_cloud_licensing_enabled) { false }

      include_examples 'skips resetting the submit license usage data'
    end

    context 'when current license is for a trial' do
      let(:trial) { true }

      include_examples 'skips resetting the submit license usage data'
    end

    context 'when license start day matches today\'s day' do
      include_examples 'resets the submit license usage data'
    end

    context 'when license start day does not match today\'s day' do
      context 'and today is the end of the month' do
        context 'and the start date\'s day is smaller than today\'s day' do
          let(:starts_at) { Date.new(2022, 1, 27) }

          around do |example|
            travel_to(Date.new(2022, 2, 28)) { example.run }
          end

          include_examples 'skips resetting the submit license usage data'
        end

        context 'and the start date\'s day is bigger than today\'s day' do
          where(
            current_date: [
              Date.new(2022, 2, 28),
              Date.new(2024, 2, 29),
              Date.new(2022, 4, 30)
            ]
          )

          with_them do
            let(:starts_at) { Date.new(2022, 1, 31) }

            around do |example|
              travel_to(current_date) { example.run }
            end

            include_examples 'resets the submit license usage data'
          end
        end
      end
    end
  end

  describe '#display?' do
    subject(:display) { described_class.new(user).display? }

    let_it_be(:user, refind: true) { create(:admin) }

    let(:can_admin_all_resources) { true }
    let(:check_namespace_plan) { false }
    let(:cloud_licensing_enabled) { true }
    let(:offline_cloud_licensing_enabled) { true }
    let(:trial) { false }
    let(:starts_at) { 2.months.ago.to_date }

    before do
      Gitlab::CurrentSettings.update!(license_usage_data_exported: true)

      create_current_license(
        {
          cloud_licensing_enabled: cloud_licensing_enabled,
          offline_cloud_licensing_enabled: offline_cloud_licensing_enabled,
          restrictions: { trial: trial },
          starts_at: starts_at
        }
      )

      allow(user).to receive(:can_admin_all_resources?).and_return(can_admin_all_resources) if user
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(check_namespace_plan)
    end

    context 'when user is empty' do
      let(:user) { nil }

      it { is_expected.to eq(false) }
    end

    context 'when user cannot admin all resources' do
      let(:can_admin_all_resources) { false }

      it { is_expected.to eq(false) }
    end

    context 'when check namespace plan setting is enabled' do
      let(:check_namespace_plan) { true }

      it { is_expected.to eq(false) }
    end

    context 'when current license is an online cloud license' do
      let(:offline_cloud_licensing_enabled) { false }

      it { is_expected.to eq(false) }
    end

    context 'when current license is a legacy license' do
      let(:cloud_licensing_enabled) { false }
      let(:offline_cloud_licensing_enabled) { false }

      it { is_expected.to eq(false) }
    end

    context 'when current license is for a trial' do
      let(:trial) { true }

      it { is_expected.to eq(false) }
    end

    context 'when there is only a future dated license' do
      let(:starts_at) { Date.tomorrow }

      before do
        ::License.current.destroy!
      end

      it { is_expected.to eq(false) }
    end

    context 'when it\'s within the first month of the license' do
      let(:starts_at) { 15.days.ago.to_date }

      it { is_expected.to eq(false) }
    end

    context 'when user dismissed the callout' do
      let!(:callout) { create(:callout, user: user, feature_name: feature_name, dismissed_at: 2.minutes.ago) }

      it { is_expected.to eq(false) }
    end

    it { is_expected.to eq(true) }
  end

  describe '#title' do
    subject(:title) { banner.title }

    let(:banner) { described_class.new(build(:admin)) }

    context 'when banner should not be displayed' do
      it 'does not return a title' do
        allow(banner).to receive(:display?).and_return(false)

        expect(title).to be_nil
      end
    end

    it 'returns the title' do
      allow(banner).to receive(:display?).and_return(true)

      expect(title).to eq('Report your license usage data to GitLab')
    end
  end

  describe '#body' do
    subject(:body) { strip_tags(banner.body) }

    let(:banner) { described_class.new(build(:admin)) }

    context 'when banner should not be displayed' do
      it 'does not return a body' do
        allow(banner).to receive(:display?).and_return(false)

        expect(body).to be_nil
      end
    end

    it 'returns the body' do
      allow(banner).to receive(:display?).and_return(true)

      expect(body).to eq(
        'Per your subscription agreement with GitLab, you must report your license usage data on a monthly basis. ' \
        'GitLab uses this data to keep your subscription up to date. To report your license usage data, export ' \
        "your license usage file and email it to #{Gitlab::SubscriptionPortal::RENEWAL_SERVICE_EMAIL}. If you " \
        'need an updated license, GitLab will send the license to the email address registered in the Customers ' \
        'Portal, and you can upload this license to your instance.'
      )
    end
  end

  describe '#dismissable?' do
    subject { described_class.new(build(:admin)).dismissable? }

    let(:license_usage_data_exported) { true }

    before do
      Gitlab::CurrentSettings.update!(license_usage_data_exported: license_usage_data_exported)
    end

    context 'when license usage data has not been exported yet' do
      let(:license_usage_data_exported) { false }

      it { is_expected.to eq(false) }
    end

    it { is_expected.to eq(true) }
  end
end
