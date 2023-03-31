# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ManualQuarterlyCoTermBanner do
  include ActionView::Helpers::SanitizeHelper

  let(:manual_quarterly_co_term_banner) { described_class.new(upcoming_reconciliation) }

  let(:upcoming_reconciliation) do
    build(:upcoming_reconciliation, :self_managed, next_reconciliation_date: next_reconciliation_date)
  end

  let(:next_reconciliation_date) { Date.current + 60.days }
  let(:offline_license?) { true }
  let(:seat_reconciliation?) { true }

  before do
    create_current_license(
      {
        cloud_licensing_enabled: true,
        offline_cloud_licensing_enabled: offline_license?,
        seat_reconciliation_enabled: seat_reconciliation?
      }
    )
  end

  describe '#display?' do
    subject(:display?) { manual_quarterly_co_term_banner.display? }

    let(:should_check_namespace_plan?) { false }

    before do
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { should_check_namespace_plan? }
    end

    context 'when on GitLab.com' do
      let(:should_check_namespace_plan?) { true }

      it { is_expected.to eq(false) }
    end

    context 'when current license is not an offline cloud license' do
      let(:offline_license?) { false }

      it { is_expected.to eq(false) }
    end

    context 'when seat reconciliation is false' do
      let(:seat_reconciliation?) { false }

      it { is_expected.to eq(false) }
    end

    context 'when upcoming reconciliation is nil' do
      let(:upcoming_reconciliation) { nil }

      it { is_expected.to eq(false) }
    end

    context 'when expiration date is not within the notification window' do
      let(:next_reconciliation_date) { Date.tomorrow + described_class::REMINDER_DAYS }

      it { is_expected.to eq(false) }
    end

    context 'when reconciliation date is within the notification window' do
      context 'when notification window starts today' do
        let(:next_reconciliation_date) { Date.current + described_class::REMINDER_DAYS }

        it { is_expected.to eq(true) }
      end

      context 'when notification window is already on going' do
        let(:next_reconciliation_date) { Date.yesterday + described_class::REMINDER_DAYS }

        it { is_expected.to eq(true) }
      end
    end
  end

  describe '#title' do
    subject { manual_quarterly_co_term_banner.title }

    context 'when reconciliation is upcoming but within the notification window' do
      shared_examples 'an upcoming reconciliation' do
        it { is_expected.to eq("A quarterly reconciliation is due on #{next_reconciliation_date}") }
      end

      context 'when notification date is today' do
        let(:next_reconciliation_date) { Date.current + described_class::REMINDER_DAYS }

        it_behaves_like 'an upcoming reconciliation'
      end

      context 'when notification date is within the next 14 days' do
        let(:next_reconciliation_date) { Date.yesterday + described_class::REMINDER_DAYS }

        it_behaves_like 'an upcoming reconciliation'
      end
    end

    context 'when reconciliation is overdue' do
      let(:next_reconciliation_date) { Date.current }

      it { is_expected.to eq("A quarterly reconciliation is due on #{next_reconciliation_date}") }
    end
  end

  describe '#body' do
    subject(:body) { strip_tags(manual_quarterly_co_term_banner.body) }

    before do
      allow(manual_quarterly_co_term_banner).to receive(:display?).and_return(display)
    end

    context 'when reconciliation is upcoming and within the notification window' do
      shared_examples 'an upcoming reconciliation' do
        it 'returns a message for an upcoming reconciliation' do
          expect(body).to eq(
            "You have more active users than are allowed by your license. Before #{next_reconciliation_date} " \
              "GitLab must reconcile your subscription. To complete this process, export your license usage " \
              "file and email it to #{Gitlab::SubscriptionPortal::RENEWAL_SERVICE_EMAIL}. A new license will " \
              "be emailed to the email address registered in the Customers Portal. You can add this license " \
              "to your instance."
          )
        end
      end

      context 'when notification date is today' do
        let(:next_reconciliation_date) { Date.current + described_class::REMINDER_DAYS }

        it_behaves_like 'an upcoming reconciliation'
      end

      context 'when notification date is within the next 14 days' do
        let(:next_reconciliation_date) { Date.yesterday + described_class::REMINDER_DAYS }

        it_behaves_like 'an upcoming reconciliation'
      end
    end

    context 'when reconciliation is overdue' do
      let(:next_reconciliation_date) { Date.yesterday }

      it 'returns a message for an overdue reconciliation' do
        expect(body).to eq(
          "You have more active users than are allowed by your license. GitLab must now reconcile your " \
            "subscription. To complete this process, export your license usage file and email it to " \
            "#{Gitlab::SubscriptionPortal::RENEWAL_SERVICE_EMAIL}. A new license will be emailed to the " \
            "email address registered in the Customers Portal. You can add this license to your instance."
        )
      end
    end
  end

  describe 'display_error_version?' do
    subject(:display_error_version?) { manual_quarterly_co_term_banner.display_error_version? }

    context 'when reconciliation is not overdue yet' do
      let(:next_reconciliation_date) { Date.current }

      it { is_expected.to eq(false) }
    end

    context 'when reconciliation is overdue' do
      let(:next_reconciliation_date) { Date.yesterday }

      it { is_expected.to eq(true) }
    end
  end
end
