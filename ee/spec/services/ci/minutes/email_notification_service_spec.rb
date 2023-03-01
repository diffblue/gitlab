# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::EmailNotificationService, feature_category: :continuous_integration do
  include ::Ci::MinutesHelpers

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.new(project).execute }

    where(:monthly_minutes_limit, :minutes_used, :current_notification_level, :new_notification_level, :result) do
      1000 | 500  | 100 | 100 | [false]
      1000 | 800  | 100 | 30  | [true, 30]
      1000 | 800  | 30  | 30  | [false]
      1000 | 950  | 100 | 5   | [true, 5]
      1000 | 950  | 30  | 5   | [true, 5]
      1000 | 950  | 5   | 5   | [false]
      1000 | 1000 | 100 | 0   | [true, 0]
      1000 | 1000 | 30  | 0   | [true, 0]
      1000 | 1000 | 5   | 0   | [true, 0]
      1000 | 1001 | 5   | 0   | [true, 0]
      1000 | 1000 | 0   | 0   | [false]
      0    | 1000 | 100 | 100 | [false]
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
      end

      let_it_be(:user) { create(:user) }
      let_it_be(:user_2) { create(:user) }

      let(:project) { create(:project, namespace: namespace) }

      let(:namespace_usage) do
        Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: namespace.id)
      end

      before do
        namespace_usage.update!(amount_used: minutes_used, notification_level: current_notification_level)
        namespace.update_column(:shared_runners_minutes_limit, monthly_minutes_limit)
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
  end
end
