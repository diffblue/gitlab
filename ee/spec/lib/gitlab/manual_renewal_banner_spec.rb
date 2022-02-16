# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ManualRenewalBanner do
  include ActionView::Helpers::SanitizeHelper

  let(:manual_renewal_banner) { described_class.new(actionable: license) }
  let(:license) { build(:license, expires_at: expires_at, plan: plan) }
  let(:expires_at) { Date.current + 1.year }
  let(:plan) { License::ULTIMATE_PLAN }
  let(:offline_license?) { true }

  before do
    create_current_license({ cloud_licensing_enabled: true, offline_cloud_licensing_enabled: offline_license? })
  end

  describe '#display?' do
    subject(:display?) { manual_renewal_banner.display? }

    let(:should_check_namespace_plan?) { false } # indicates a self-managed instance
    let(:feature_flag_enabled) { true }

    before do
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { should_check_namespace_plan? }

      stub_feature_flags(automated_email_provision: feature_flag_enabled)
    end

    context 'when on GitLab.com' do
      let(:should_check_namespace_plan?) { true }

      it { is_expected.to eq(false) }
    end

    context 'when feature flag :automated_email_provision is disabled' do
      let(:feature_flag_enabled) { false }

      it { is_expected.to eq(false) }
    end

    context 'when current license is not an offline cloud license' do
      let(:offline_license?) { false }

      it { is_expected.to eq(false) }
    end

    context 'when license does not expire' do
      let(:expires_at) { nil }

      it { is_expected.to eq(false) }
    end

    context 'when a future dated license is present' do
      before do
        allow(License).to receive(:future_dated).and_return(build(:license))
      end

      it { is_expected.to eq(false) }
    end

    context 'when expiration date is not within the notification window' do
      let(:expires_at) { Date.tomorrow + described_class::REMINDER_DAYS }

      it { is_expected.to eq(false) }
    end

    context 'when expiration date is within the notification window' do
      context 'when notification window starts today' do
        let(:expires_at) { Date.today + described_class::REMINDER_DAYS }

        it { is_expected.to eq(true) }
      end

      context 'when notification window is already on going' do
        let(:expires_at) { Date.yesterday + described_class::REMINDER_DAYS }

        it { is_expected.to eq(true) }
      end
    end
  end

  describe '#subject' do
    subject { manual_renewal_banner.subject }

    before do
      allow(manual_renewal_banner).to receive(:display?).and_return(display)
    end

    context 'when banner should not be displayed' do
      let(:display) { false }

      it { is_expected.to eq(nil) }
    end

    context 'when banner should be displayed' do
      let(:display) { true }

      context 'when license is not yet expired but within the notification window' do
        shared_examples 'an expiring license' do
          it { is_expected.to eq("Your #{plan.capitalize} subscription expires on #{license.expires_at}") }
        end

        context 'when notification date is today' do
          let(:expires_at) { Date.today + described_class::REMINDER_DAYS }

          it_behaves_like 'an expiring license'
        end

        context 'when notification date is within the next 14 days' do
          let(:expires_at) { Date.yesterday + described_class::REMINDER_DAYS }

          it_behaves_like 'an expiring license'
        end
      end

      context 'when license is already expired' do
        let(:expires_at) { Date.today }

        it { is_expected.to eq("Your #{plan.capitalize} subscription expired on #{license.expires_at}") }
      end
    end
  end

  describe '#body' do
    subject(:body) { strip_tags(manual_renewal_banner.body) }

    before do
      allow(manual_renewal_banner).to receive(:display?).and_return(display)
    end

    context 'when banner should not be displayed' do
      let(:display) { false }

      it { is_expected.to eq(nil) }
    end

    context 'when banner should be displayed' do
      let(:display) { true }

      context 'when license is not yet expired but within the notification window' do
        shared_examples 'an expiring license' do
          it 'returns a message to renew for an expiring license' do
            expect(body).to eq(
              "To renew, export your license usage file and email it to " \
                "#{Gitlab::SubscriptionPortal::RENEWAL_SERVICE_EMAIL}. A new license will be emailed to the email " \
                "address registered in the Customers Portal. You can upload this license to your instance."
            )
          end
        end

        context 'when notification date is today' do
          let(:expires_at) { Date.today + described_class::REMINDER_DAYS }

          it_behaves_like 'an expiring license'
        end

        context 'when notification date is within the next 14 days' do
          let(:expires_at) { Date.yesterday + described_class::REMINDER_DAYS }

          it_behaves_like 'an expiring license'
        end
      end

      context 'when license is already expired' do
        let(:expires_at) { Date.today }

        it 'returns a message to renew for an expired license' do
          expect(body).to eq(
            "Your subscription is now expired. To renew, export your license usage file and email it to " \
              "#{Gitlab::SubscriptionPortal::RENEWAL_SERVICE_EMAIL}. A new license will be emailed to the email " \
              "address registered in the Customers Portal. You can upload this license to your instance. To use " \
              "Free tier, remove your current license."
          )
        end
      end
    end
  end

  describe 'display_error_version?' do
    subject(:display_error_version?) { manual_renewal_banner.display_error_version? }

    context 'when license is not expired' do
      it { is_expected.to eq(false) }
    end

    context 'when license is expired' do
      let(:expires_at) { Date.today }

      it { is_expected.to eq(true) }
    end
  end
end
