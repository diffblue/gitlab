# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::EmailNotificationService do
  include ::Ci::MinutesHelpers

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.new(project).execute }

    where(:monthly_minutes_limit, :minutes_used, :current_notification_level, :new_notification_level, :legacy_minutes_used, :legacy_current_notification_level, :legacy_new_notification_level, :result) do
      # when legacy and new tracking usage matches
      1000 | 500  | 100 | 100 | 500  | 100 | 100 | [false]
      1000 | 800  | 100 | 30  | 800  | 100 | 30  | [true, 30]
      1000 | 800  | 30  | 30  | 800  | 30  | 30  | [false]
      1000 | 950  | 100 | 5   | 950  | 100 | 5   | [true, 5]
      1000 | 950  | 30  | 5   | 950  | 30  | 5   | [true, 5]
      1000 | 950  | 5   | 5   | 950  | 5   | 5   | [false]
      1000 | 1000 | 100 | 0   | 1000 | 100 | 0   | [true, 0]
      1000 | 1000 | 30  | 0   | 1000 | 30  | 0   | [true, 0]
      1000 | 1000 | 5   | 0   | 1000 | 5   | 0   | [true, 0]
      1000 | 1001 | 5   | 0   | 1001 | 5   | 0   | [true, 0]
      1000 | 1000 | 0   | 0   | 1000 | 0   | 0   | [false]
      0    | 1000 | 100 | 100 | 1000 | 100 | 100 | [false]

      # when legacy and new tracking usage doesn't match we send notifications
      # based on the feature flag.
      1000 | 500  | 100 | 100 | 800  | 100 | 30  | [false]
      1000 | 800  | 100 | 30  | 500  | 100 | 100 | [true, 30]
      1000 | 950  | 100 | 5   | 800  | 100 | 30  | [true, 5]
      1000 | 950  | 100 | 5   | 1001 | 30  | 0   | [true, 5]
    end

    with_them do
      shared_examples 'matches the expectations' do
        it 'matches the expectation on the email sent' do
          email_sent, level_notified = result

          if email_sent
            if level_notified > 0
              expect(CiMinutesUsageMailer)
                .to receive(:notify_limit)
                .with(namespace, match_array(recipients), level_notified)
                .and_call_original
            else
              expect(CiMinutesUsageMailer)
                .to receive(:notify)
                .with(namespace, match_array(recipients))
                .and_call_original
            end
          else
            expect(CiMinutesUsageMailer).not_to receive(:notify_limit)
            expect(CiMinutesUsageMailer).not_to receive(:notify)
          end

          subject
        end

        it 'matches the updated notification level' do
          subject

          expect(namespace_usage.reload.notification_level).to eq(new_notification_level)
        end

        it 'matches the updated legacy notification level' do
          subject

          if legacy_new_notification_level == 0
            expect(namespace.reload.last_ci_minutes_notification_at).to be_present
          elsif legacy_new_notification_level == 100
            expect(namespace.reload.last_ci_minutes_notification_at).to be_nil
            expect(namespace.reload.last_ci_minutes_usage_notification_level).to be_nil
          else
            expect(namespace.reload.last_ci_minutes_usage_notification_level).to eq(legacy_new_notification_level)
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
        if namespace.namespace_statistics
          namespace.namespace_statistics.update!(shared_runners_seconds: legacy_minutes_used.minutes)
        else
          namespace.create_namespace_statistics(shared_runners_seconds: legacy_minutes_used.minutes)
        end

        namespace_usage.update!(amount_used: minutes_used)

        namespace_usage.update_column(:notification_level, current_notification_level)
        namespace.update_column(:shared_runners_minutes_limit, monthly_minutes_limit)

        if legacy_current_notification_level == 0
          namespace.update_column(:last_ci_minutes_notification_at, Time.current)
        elsif current_notification_level != 100
          namespace.update_column(:last_ci_minutes_usage_notification_level, legacy_current_notification_level)
        end
      end

      context 'when on personal namespace' do
        let(:namespace) { create(:namespace, owner: user) }
        let(:recipients) { [user.email] }

        it_behaves_like 'matches the expectations'
      end

      context 'when on group' do
        let(:namespace) { create(:group) }
        let(:recipients) { [user.email, user_2.email] }

        before do
          namespace.add_owner(user)
          namespace.add_owner(user_2)
        end

        it_behaves_like 'matches the expectations'
      end
    end

    context 'legacy path - to remove' do
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

      where(:monthly_minutes_limit, :minutes_used, :legacy_minutes_used, :current_notification_level, :legacy_notification_level, :result, :legacy_result) do
        1000 | 500  | 500  | 100 | 100 | [:not_notified] | [:not_notified]
        1000 | 800  | 800  | 100 | 100 | [:notified, 30] | [:notified, 30]
        1000 | 800  | 800  | 30  | 30  | [:not_notified] | [:not_notified]
        1000 | 950  | 950  | 100 | 100 | [:notified, 5]  | [:notified, 5]
        1000 | 950  | 950  | 30  | 30  | [:notified, 5]  | [:notified, 5]
        1000 | 950  | 950  | 5   | 5   | [:not_notified] | [:not_notified]
        1000 | 1000 | 1000 | 100 | 100 | [:notified, 0]  | [:notified, 0]
        1000 | 1000 | 1000 | 30  | 30  | [:notified, 0]  | [:notified, 0]
        1000 | 1000 | 1000 | 5   | 5   | [:notified, 0]  | [:notified, 0]
        1000 | 1001 | 1001 | 5   | 5   | [:notified, 0]  | [:notified, 0]
        1000 | 1000 | 1000 | 0   | 0   | [:not_notified] | [:not_notified]
        0    | 1000 | 1000 | 100 | 100 | [:not_notified] | [:not_notified]
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
          if namespace.namespace_statistics
            namespace.namespace_statistics.update!(shared_runners_seconds: legacy_minutes_used.minutes)
          else
            namespace.create_namespace_statistics(shared_runners_seconds: legacy_minutes_used.minutes)
          end

          namespace_usage.update!(amount_used: minutes_used)

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
        end

        context 'when on group' do
          let(:namespace) { create(:group) }
          let(:recipients) { [user.email, user_2.email] }

          before do
            namespace.add_owner(user)
            namespace.add_owner(user_2)
          end

          it_behaves_like 'matches the expectation'
        end
      end
    end
  end
end
