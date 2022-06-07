# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Licenses::SubmitLicenseUsageDataBanner do
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

    context 'when feature flag :automated_email_provision is disabled' do
      before do
        stub_feature_flags(automated_email_provision: false)
      end

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
end
