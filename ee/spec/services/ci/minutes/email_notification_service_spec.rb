# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::EmailNotificationService do
  include ::Ci::MinutesHelpers

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.new(project).execute }

    def expect_warning_usage_notification(new_notification_level)
      expect(CiMinutesUsageMailer)
        .to receive(:notify_limit)
        .with(namespace, match_array(recipients), new_notification_level)
        .and_call_original

      subject

      expect(namespace_usage.reload.notification_level).to eq(new_notification_level)
      expect(namespace.reload.last_ci_minutes_usage_notification_level).to eq(new_notification_level)
    end

    def expect_quota_exceeded_notification
      expect(CiMinutesUsageMailer)
        .to receive(:notify)
        .with(namespace, match_array(recipients))
        .and_call_original

      subject

      expect(namespace_usage.reload.notification_level).to eq(0)
      expect(namespace.reload.last_ci_minutes_notification_at).to be_present
    end

    def expect_no_notification(current_notification_level)
      expect(CiMinutesUsageMailer)
        .not_to receive(:notify_limit)
      expect(CiMinutesUsageMailer)
        .not_to receive(:notify)

      subject

      # notification level remains the same
      expect(namespace_usage.reload.notification_level).to eq(current_notification_level)
    end

    where(:monthly_minutes_limit, :minutes_used, :current_notification_level, :result) do
      1000 | 500  | 100 | [:not_notified]
      1000 | 800  | 100 | [:notified, 30]
      1000 | 800  | 30  | [:not_notified]
      1000 | 950  | 100 | [:notified, 5]
      1000 | 950  | 30  | [:notified, 5]
      1000 | 950  | 5   | [:not_notified]
      1000 | 1000 | 100 | [:notified, 0]
      1000 | 1000 | 30  | [:notified, 0]
      1000 | 1000 | 5   | [:notified, 0]
      1000 | 1001 | 5   | [:notified, 0]
      1000 | 1000 | 0   | [:not_notified]
      0    | 1000 | 100 | [:not_notified]
    end

    with_them do
      shared_examples 'matches the expectation' do
        it 'matches the expectation' do
          expectation, new_notification_level = result

          if expectation == :notified && new_notification_level > 0
            expect_warning_usage_notification(new_notification_level)

          elsif expectation == :notified && new_notification_level == 0
            expect_quota_exceeded_notification

          elsif expectation == :not_notified
            expect_no_notification(current_notification_level)

          else
            raise 'unexpected test scenario'
          end
        end
      end

      let_it_be(:user) { create(:user) }
      let_it_be(:user_2) { create(:user) }

      let(:project) { create(:project, namespace: namespace) }

      let(:namespace_usage) do
        Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: namespace.id)
      end

      before do
        set_ci_minutes_used(namespace, minutes_used)

        namespace_usage.update_column(:notification_level, current_notification_level)
        namespace.update_column(:shared_runners_minutes_limit, monthly_minutes_limit)

        if current_notification_level == 0
          namespace.update_column(:last_ci_minutes_notification_at, Time.current)
        elsif current_notification_level != 100
          namespace.update_column(:last_ci_minutes_usage_notification_level, current_notification_level)
        end
      end

      context 'when on personal namespace' do
        let(:namespace) { create(:namespace, owner: user) }
        let(:recipients) { [user.email] }

        it_behaves_like 'matches the expectation'

        context 'when feature flag ci_minutes_use_notification_level is disabled' do
          before do
            stub_feature_flags(ci_minutes_use_notification_level: false)
          end

          it_behaves_like 'matches the expectation'
        end
      end

      context 'when on group' do
        let(:namespace) { create(:group) }
        let(:recipients) { [user.email, user_2.email] }

        before do
          namespace.add_owner(user)
          namespace.add_owner(user_2)
        end

        it_behaves_like 'matches the expectation'

        context 'when feature flag ci_minutes_use_notification_level is disabled' do
          before do
            stub_feature_flags(ci_minutes_use_notification_level: false)
          end

          it_behaves_like 'matches the expectation'
        end
      end
    end
  end
end
