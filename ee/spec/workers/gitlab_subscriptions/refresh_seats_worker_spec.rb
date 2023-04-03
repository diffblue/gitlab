# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::RefreshSeatsWorker, :saas, feature_category: :seat_cost_management do
  let(:db_is_read_only) { false }
  let(:worker) { described_class.new }

  describe '#perform_work' do
    subject(:perform_work) { worker.perform_work }

    before do
      allow(Gitlab::Database).to receive(:read_only?).and_return(db_is_read_only)
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(true)
    end

    shared_examples 'updates nothing' do
      it 'does not update seat columns' do
        expect do
          perform_work
          gitlab_subscription.reload
        end.to not_change { gitlab_subscription.max_seats_used }
          .and not_change { gitlab_subscription.seats_in_use }
          .and not_change { gitlab_subscription.seats_owed }
          .and not_change { gitlab_subscription.max_seats_used_changed_at }
          .and not_change { gitlab_subscription.last_seat_refresh_at }
      end
    end

    context 'with GitlabSubscriptions requiring refresh', :freeze_time do
      let_it_be(:gitlab_subscription, refind: true) do
        create(:gitlab_subscription,
          namespace: create(:namespace, :with_namespace_settings),
          seats: 2,
          last_seat_refresh_at: 25.hours.ago
        )
      end

      context 'when the DB is not read-only' do
        let_it_be(:premium_plan) { create(:premium_plan) }

        let(:subscription_attrs) { nil }

        before do
          gitlab_subscription.update!(subscription_attrs) if subscription_attrs
        end

        context 'with a paid plan' do
          let(:subscription_attrs) { { hosted_plan: premium_plan } }

          before do
            allow_next_found_instance_of(GitlabSubscription) do |subscription|
              allow(subscription).to receive(:refresh_seat_attributes) do
                subscription.max_seats_used = subscription.seats + 3
                subscription.seats_in_use = subscription.seats + 2
                subscription.seats_owed = subscription.seats + 1
              end
            end
          end

          include_examples 'an idempotent worker' do
            it 'updates seat count columns' do
              expect do
                perform_work
                gitlab_subscription.reload
              end.to change { gitlab_subscription.max_seats_used }.from(0).to(5)
                .and change { gitlab_subscription.seats_in_use }.from(0).to(4)
                .and change { gitlab_subscription.seats_owed }.from(0).to(3)
                .and change { gitlab_subscription.max_seats_used_changed_at }.from(nil).to(be_like_time(Time.current))
                .and change { gitlab_subscription.last_seat_refresh_at }.to(be_like_time(Time.current))
            end

            it 'updates last_seat_refresh_at without callbacks' do
              expect_next_found_instance_of(GitlabSubscription) do |subscription|
                expect(subscription).to receive(:update_column).with(:last_seat_refresh_at, Time.current)
              end

              perform_work
            end
          end
        end

        context 'with a free plan' do
          let(:subscription_attrs) { { hosted_plan: nil } }

          include_examples 'updates nothing'
        end

        context 'with a trial plan' do
          let(:subscription_attrs) { { hosted_plan: premium_plan, trial: true } }

          include_examples 'updates nothing'
        end
      end

      context 'when the database is read_only' do
        let(:db_is_read_only) { true }

        include_examples 'updates nothing'
      end
    end

    context 'with no GitlabSubscriptions requiring refresh' do
      let_it_be(:gitlab_subscription) do
        create(
          :gitlab_subscription,
          namespace: create(:namespace, :with_namespace_settings),
          seats: 11,
          max_seats_used: 11,
          last_seat_refresh_at: 1.hour.ago.to_s(:db)
        )
      end

      include_examples 'updates nothing'
    end
  end

  describe '#max_running_jobs' do
    subject { worker.max_running_jobs }

    it { is_expected.to eq(described_class::MAX_RUNNING_JOBS) }
  end

  describe '#remaining_work_count', :freeze_time do
    let_it_be(:subscriptions_requiring_refresh) do
      create_list(:gitlab_subscription, 8, last_seat_refresh_at: 3.days.ago)
    end

    subject(:remaining_work_count) { worker.remaining_work_count }

    context 'when there is remaining work' do
      it { is_expected.to eq(described_class::MAX_RUNNING_JOBS + 1) }
    end

    context 'when there is no remaining work' do
      before do
        subscriptions_requiring_refresh.map { |sub| sub.update!(last_seat_refresh_at: Time.current) }
      end

      it { is_expected.to eq(0) }
    end
  end
end
