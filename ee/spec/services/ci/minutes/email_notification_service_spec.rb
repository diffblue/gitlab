# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::EmailNotificationService do
  shared_examples 'namespace with available CI minutes' do
    context 'when usage is below the quote' do
      it 'does not send the email' do
        expect(CiMinutesUsageMailer).not_to receive(:notify)

        subject
      end
    end
  end

  shared_examples 'namespace with all CI minutes used' do
    context 'when usage is over the quote' do
      it 'sends the email to the owner' do
        expect(CiMinutesUsageMailer).to receive(:notify).once.with(namespace, [user.email]).and_return(spy)

        subject
      end
    end
  end

  let(:project) { create(:project, namespace: namespace) }
  let(:user) { create(:user) }
  let(:user_2) { create(:user) }
  let(:ci_minutes_used) { 0 }

  let!(:namespace_statistics) do
    create(:namespace_statistics, namespace: namespace, shared_runners_seconds: ci_minutes_used * 60)
  end

  let(:namespace_usage) do
    Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: namespace.id)
  end

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.new(project).execute }

    def expect_warning_usage_notification(new_notification_level)
      expect(CiMinutesUsageMailer)
        .to receive(:notify_limit)
        .with(namespace, match_array([user.email, user_2.email]), new_notification_level)
        .and_call_original

      subject

      expect(namespace_usage.reload.notification_level).to eq(new_notification_level)
      expect(namespace.reload.last_ci_minutes_usage_notification_level).to eq(new_notification_level)
    end

    def expect_quota_exceeded_notification
      expect(CiMinutesUsageMailer)
        .to receive(:notify)
        .with(namespace, match_array([user.email, user_2.email]))
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
      let_it_be_with_reload(:namespace) { create(:group) }
      let_it_be_with_reload(:project) { create(:project, namespace: namespace) }

      let!(:namespace_statistics) do
        create(:namespace_statistics, namespace: namespace, shared_runners_seconds: minutes_used * 60)
      end

      let(:namespace_usage) do
        Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: namespace.id)
      end

      before do
        namespace_usage.update_column(:notification_level, current_notification_level)
        namespace.update_column(:shared_runners_minutes_limit, monthly_minutes_limit)
        namespace.add_owner(user)
        namespace.add_owner(user_2)

        if current_notification_level == 0
          namespace.update_column(:last_ci_minutes_notification_at, Time.current)
        elsif current_notification_level != 100
          namespace.update_column(:last_ci_minutes_usage_notification_level, current_notification_level)
        end
      end

      it_behaves_like 'matches the expectation'

      context 'when feature flag ci_minutes_use_notification_level is disabled' do
        before do
          stub_feature_flags(ci_minutes_use_notification_level: false)
        end

        it_behaves_like 'matches the expectation'
      end
    end

    let(:extra_ci_minutes) { 0 }
    let(:namespace) do
      create(:namespace, shared_runners_minutes_limit: 2000, extra_shared_runners_minutes_limit: extra_ci_minutes)
    end

    context 'with a personal namespace' do
      before do
        namespace.update!(owner_id: user.id)
      end

      it_behaves_like 'namespace with available CI minutes' do
        let(:ci_minutes_used) { 1900 }
      end

      it_behaves_like 'namespace with all CI minutes used' do
        let(:ci_minutes_used) { 2500 }
      end
    end

    context 'with a Group' do
      let!(:namespace) do
        create(:group, shared_runners_minutes_limit: 2000, extra_shared_runners_minutes_limit: extra_ci_minutes)
      end

      context 'with a single owner' do
        before do
          namespace.add_owner(user)
        end

        it_behaves_like 'namespace with available CI minutes' do
          let(:ci_minutes_used) { 1900 }
        end

        it_behaves_like 'namespace with all CI minutes used' do
          let(:ci_minutes_used) { 2500 }
        end

        context 'with extra CI minutes' do
          let(:extra_ci_minutes) { 1000 }

          it_behaves_like 'namespace with available CI minutes' do
            let(:ci_minutes_used) { 2500 }
          end

          it_behaves_like 'namespace with all CI minutes used' do
            let(:ci_minutes_used) { 3100 }
          end
        end
      end

      context 'with multiple owners' do
        before do
          namespace.add_owner(user)
          namespace.add_owner(user_2)
        end

        it_behaves_like 'namespace with available CI minutes' do
          let(:ci_minutes_used) { 1900 }
        end

        context 'when usage is over the quote' do
          let(:ci_minutes_used) { 2001 }

          it 'sends the email to all the owners' do
            expect(CiMinutesUsageMailer).to receive(:notify)
              .with(namespace, match_array([user_2.email, user.email]))
              .and_return(spy)

            subject
          end

          context 'when we have already notified the user that their quota is used up' do
            before do
              namespace_usage.update_column(:notification_level, 0)
            end

            it 'does not notify owners' do
              expect(CiMinutesUsageMailer).not_to receive(:notify)

              subject
            end
          end

          context 'when ci_minutes_use_notification_level feature flag is disabled' do
            before do
              stub_feature_flags(ci_minutes_use_notification_level: false)
            end

            context 'when last_ci_minutes_notification_at has a value' do
              before do
                namespace.update_column(:last_ci_minutes_notification_at, Time.current)
              end

              it 'does not notify owners' do
                expect(CiMinutesUsageMailer).not_to receive(:notify)

                subject
              end
            end
          end
        end
      end
    end
  end

  describe 'CI usage limit approaching' do
    let(:namespace) { create(:group, shared_runners_minutes_limit: 2000) }

    def notify_owners
      described_class.new(project).execute
    end

    shared_examples 'no notification is sent' do
      it 'does not notify owners' do
        expect(CiMinutesUsageMailer).not_to receive(:notify_limit)

        notify_owners
      end
    end

    shared_examples 'notification for custom level is sent' do |minutes_used, expected_level|
      before do
        namespace_statistics.update_column(:shared_runners_seconds, minutes_used * 60)
      end

      it 'notifies the the owners about it' do
        expect(CiMinutesUsageMailer).to receive(:notify_limit)
          .with(namespace, array_including(user_2.email, user.email), expected_level)
          .and_call_original

        notify_owners
      end
    end

    before do
      namespace.add_owner(user)
      namespace.add_owner(user_2)
    end

    context 'when available minutes are above notification levels' do
      let(:ci_minutes_used) { 1000 }

      it_behaves_like 'no notification is sent'
    end

    context 'when available minutes have reached the first level of alert' do
      context 'when quota is unlimited' do
        let(:ci_minutes_used) { 1500 }

        before do
          namespace.update_column(:shared_runners_minutes_limit, 0)
        end

        it_behaves_like 'no notification is sent'
      end

      it_behaves_like 'notification for custom level is sent', 1500, 30

      context 'when other Pipeline has finished but second level of alert has not been reached' do
        before do
          namespace_statistics.update_column(:shared_runners_seconds, 1500 * 60)
          notify_owners

          namespace_statistics.update_column(:shared_runners_seconds, 1600 * 60)
        end

        it_behaves_like 'no notification is sent'
      end
    end

    context 'when available minutes have reached the second level of alert' do
      it_behaves_like 'notification for custom level is sent', 1500, 30

      it_behaves_like 'notification for custom level is sent', 1980, 5
    end

    context 'when there are not available minutes to use' do
      let(:ci_minutes_used) { 2001 }

      it 'notifies owners' do
        expect(CiMinutesUsageMailer)
          .to receive(:notify)
          .with(namespace, array_including(user_2.email, user.email))
          .and_call_original

        notify_owners
      end
    end
  end
end
