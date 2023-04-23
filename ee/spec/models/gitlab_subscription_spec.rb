# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscription, :saas, feature_category: :subscription_management do
  using RSpec::Parameterized::TableSyntax

  %i[free_plan bronze_plan premium_plan ultimate_plan].each do |plan| # rubocop:disable RSpec/UselessDynamicDefinition
    let_it_be(plan) { create(plan) } # rubocop:disable Rails/SaveBang
  end

  it { is_expected.to delegate_method(:exclude_guests?).to(:namespace) }

  describe 'default values', :freeze_time do
    it 'defaults start_date to the current date' do
      expect(subject.start_date).to eq(Date.today)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:seats) }
    it { is_expected.to validate_presence_of(:start_date) }

    it do
      subject.namespace = create(:namespace)
      is_expected.to validate_uniqueness_of(:namespace_id)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:hosted_plan) }
  end

  describe 'scopes' do
    describe '.with_hosted_plan' do
      let!(:ultimate_subscription) { create(:gitlab_subscription, hosted_plan: ultimate_plan) }
      let!(:premium_subscription) { create(:gitlab_subscription, hosted_plan: premium_plan) }

      let!(:trial_subscription) { create(:gitlab_subscription, hosted_plan: ultimate_plan, trial: true) }

      it 'scopes to the plan' do
        expect(described_class.with_hosted_plan('ultimate')).to contain_exactly(ultimate_subscription)
        expect(described_class.with_hosted_plan('premium')).to contain_exactly(premium_subscription)
        expect(described_class.with_hosted_plan('bronze')).to be_empty
      end
    end

    describe '.max_seats_used_changed_between', :timecop do
      let(:from) { Time.current.beginning_of_day - 1.day }
      let(:to) { Time.current.beginning_of_day }

      let!(:in_bounds_subscription) do
        create(:gitlab_subscription, max_seats_used_changed_at: to - 1.hour)
      end

      let!(:out_of_bounds_subscription) do
        create(:gitlab_subscription, max_seats_used_changed_at: from - 1.hour)
      end

      it 'returns relevant subscriptions' do
        expect(described_class.max_seats_used_changed_between(from: from, to: to))
          .to contain_exactly(in_bounds_subscription)
      end
    end

    describe '.requiring_seat_refresh', :timecop do
      let_it_be(:ultimate_subscription) { create(:gitlab_subscription, hosted_plan: ultimate_plan, last_seat_refresh_at: nil) }
      let_it_be(:ultimate_subscription_12_hours) { create(:gitlab_subscription, hosted_plan: ultimate_plan, last_seat_refresh_at: 12.hours.ago) }
      let_it_be(:ultimate_subscription_2_days) { create(:gitlab_subscription, hosted_plan: ultimate_plan, last_seat_refresh_at: 2.days.ago) }
      let_it_be(:ultimate_subscription_24_hours) { create(:gitlab_subscription, hosted_plan: ultimate_plan, last_seat_refresh_at: 24.hours.ago) }

      let_it_be(:premium_subscription) { create(:gitlab_subscription, hosted_plan: premium_plan, last_seat_refresh_at: nil) }
      let_it_be(:premium_subscription_12_hours) { create(:gitlab_subscription, hosted_plan: premium_plan, last_seat_refresh_at: 12.hours.ago) }
      let_it_be(:premium_subscription_2_days) { create(:gitlab_subscription, hosted_plan: premium_plan, last_seat_refresh_at: 2.days.ago) }
      let_it_be(:premium_subscription_24_hours) { create(:gitlab_subscription, hosted_plan: premium_plan, last_seat_refresh_at: 24.hours.ago) }

      let_it_be(:free_subscription) { create(:gitlab_subscription, :free, last_seat_refresh_at: 2.days.ago) }
      let_it_be(:trial_subscription) { create(:gitlab_subscription, hosted_plan: ultimate_plan, trial: true, last_seat_refresh_at: 2.days.ago) }

      it 'returns relevant subscriptions' do
        matching_subscriptions = [
          ultimate_subscription,
          ultimate_subscription_2_days,
          ultimate_subscription_24_hours,
          premium_subscription,
          premium_subscription_2_days,
          premium_subscription_24_hours
        ]

        expect(described_class.requiring_seat_refresh(6))
          .to match_array(matching_subscriptions)
      end

      it 'limits results' do
        expect(described_class.requiring_seat_refresh(1).size).to eq 1
      end
    end
  end

  describe '#calculate_seats_in_use' do
    let!(:user_1)         { create(:user) }
    let!(:user_2)         { create(:user) }
    let!(:blocked_user)   { create(:user, :blocked) }
    let!(:user_namespace) { create(:user).namespace }
    let!(:user_project)   { create(:project, namespace: user_namespace) }

    let!(:group)               { create(:group) }
    let!(:subgroup_1)          { create(:group, parent: group) }
    let!(:subgroup_2)          { create(:group, parent: group) }
    let!(:gitlab_subscription) { create(:gitlab_subscription, namespace: group) }

    it 'returns count of members' do
      group.add_developer(user_1)

      expect(gitlab_subscription.calculate_seats_in_use).to eq(1)
    end

    it 'also counts users from subgroups' do
      group.add_developer(user_1)
      subgroup_1.add_developer(user_2)

      expect(gitlab_subscription.calculate_seats_in_use).to eq(2)
    end

    it 'does not count duplicated members' do
      group.add_developer(user_1)
      subgroup_1.add_developer(user_2)
      subgroup_2.add_developer(user_2)

      expect(gitlab_subscription.calculate_seats_in_use).to eq(2)
    end

    it 'does not count blocked members' do
      group.add_developer(user_1)
      group.add_developer(blocked_user)

      expect(group.member_count).to eq(2)
      expect(gitlab_subscription.calculate_seats_in_use).to eq(1)
    end

    context 'with free_user_cap' do
      before do
        group.add_developer(user_1)
        group.add_developer(user_2)
        create(:group_member, :awaiting, source: group)

        gitlab_subscription.update!(plan_code: 'free')
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      it 'does not count awaiting members' do
        expect(group.member_count).to eq(3)
        expect(gitlab_subscription.calculate_seats_in_use).to eq(2)
      end
    end

    context 'with guest members' do
      before do
        group.add_guest(user_1)
      end

      context 'with a ultimate plan' do
        it 'excludes these members' do
          gitlab_subscription.update!(plan_code: 'ultimate')

          expect(gitlab_subscription.calculate_seats_in_use).to eq(0)
        end
      end

      context 'with other plans' do
        %w[bronze premium].each do |plan|
          it 'excludes these members' do
            gitlab_subscription.update!(plan_code: plan)
            # plan has already memoized in ee/namespace.rb as `actual_plan`, so this then
            # is not known at this point since `actual_plan` has already been set when
            # `group.add_guest` in the before action, and was performed due to member set logic where we
            # go through that path already
            group.clear_memoization(:actual_plan)

            expect(gitlab_subscription.calculate_seats_in_use).to eq(1)
          end
        end
      end
    end

    context 'when subscription is for a User' do
      before do
        gitlab_subscription.update!(namespace: user_namespace)

        user_project.add_developer(user_1)
        user_project.add_developer(user_2)
      end

      it 'always returns 1 seat' do
        [bronze_plan, premium_plan, ultimate_plan].each do |plan|
          gitlab_subscription.update!(hosted_plan: plan)

          expect(gitlab_subscription.calculate_seats_in_use).to eq(1)
        end
      end
    end
  end

  describe '#calculate_seats_owed' do
    let!(:gitlab_subscription) do
      create(:gitlab_subscription, subscription_attrs.merge(max_seats_used: 10, seats: 5))
    end

    shared_examples 'always returns a total of 0' do
      it 'does not update max_seats_used' do
        expect(gitlab_subscription.calculate_seats_owed).to eq(0)
      end
    end

    context 'with a free plan' do
      let(:subscription_attrs) { { hosted_plan: nil } }

      include_examples 'always returns a total of 0'
    end

    context 'with a trial plan' do
      let(:subscription_attrs) { { hosted_plan: bronze_plan, trial: true } }

      include_examples 'always returns a total of 0'
    end

    context 'with a paid plan' do
      let(:subscription_attrs) { { hosted_plan: bronze_plan } }

      it 'calculates the number of owed seats' do
        expect(gitlab_subscription.reload.calculate_seats_owed).to eq(5)
      end
    end
  end

  describe '#seats_remaining' do
    context 'when there are more seats used than available in the subscription' do
      it 'returns zero' do
        subscription = build(:gitlab_subscription, seats: 10, max_seats_used: 15)

        expect(subscription.seats_remaining).to eq 0
      end
    end

    context 'when seats used equals seats in subscription' do
      it 'returns zero' do
        subscription = build(:gitlab_subscription, seats: 10, max_seats_used: 10)

        expect(subscription.seats_remaining).to eq 0
      end
    end

    context 'when there are seats left in the subscription' do
      it 'returns the seat count remaining from the max seats used' do
        subscription = build(:gitlab_subscription, seats: 10, max_seats_used: 5)

        expect(subscription.seats_remaining).to eq 5
      end
    end

    context 'when max seat data has not yet been generated for the subscription' do
      it 'returns the seat count of the subscription' do
        subscription = build(:gitlab_subscription, seats: 10, max_seats_used: nil)

        expect(subscription.seats_remaining).to eq 10
      end
    end
  end

  describe '#refresh_seat_attributes' do
    subject(:gitlab_subscription) { create(:gitlab_subscription, seats: 3, max_seats_used: 2, seats_owed: 0) }

    before do
      expect(gitlab_subscription).to receive(:calculate_seats_in_use).and_return(calculate_seats_in_use)
    end

    context 'when current seats in use is lower than recorded max_seats_used' do
      let(:calculate_seats_in_use) { 1 }

      it 'does not increase max_seats_used' do
        expect do
          gitlab_subscription.refresh_seat_attributes
        end.to change(gitlab_subscription, :seats_in_use).from(0).to(1)
          .and not_change(gitlab_subscription, :max_seats_used)
          .and not_change(gitlab_subscription, :seats_owed)
      end
    end

    context 'when current seats in use is higher than seats and max_seats_used' do
      let(:calculate_seats_in_use) { 4 }

      it 'increases seats and max_seats_used' do
        expect do
          gitlab_subscription.refresh_seat_attributes
        end.to change(gitlab_subscription, :seats_in_use).from(0).to(4)
          .and change(gitlab_subscription, :max_seats_used).from(2).to(4)
          .and change(gitlab_subscription, :seats_owed).from(0).to(1)
      end
    end

    context 'when resetting the max seats' do
      let(:calculate_seats_in_use) { 1 }

      it 'sets max_seats_used to the current seats in use' do
        expect do
          gitlab_subscription.refresh_seat_attributes(reset_max: true)
        end.to change(gitlab_subscription, :seats_in_use).from(0).to(1)
          .and change(gitlab_subscription, :max_seats_used).from(2).to(1)
          .and not_change(gitlab_subscription, :seats_owed)
      end
    end
  end

  describe '#seats_in_use' do
    let(:group) { create(:group) }
    let!(:group_member) { create(:group_member, :developer, user: create(:user), group: group) }
    let(:hosted_plan) { nil }
    let(:seats_in_use) { 5 }
    let(:trial) { false }

    let(:gitlab_subscription) do
      create(:gitlab_subscription, namespace: group, trial: trial, hosted_plan: hosted_plan, seats_in_use: seats_in_use)
    end

    shared_examples 'a disabled feature' do
      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(seats_in_use_for_free_or_trial: false)
        end

        it 'returns the previously calculated seats in use' do
          expect(subject).to eq(5)
        end
      end
    end

    subject { gitlab_subscription.seats_in_use }

    context 'with a paid hosted plan' do
      let(:hosted_plan) { ultimate_plan }

      it 'returns the previously calculated seats in use' do
        expect(subject).to eq(5)
      end

      context 'when seats in use is 0' do
        let(:seats_in_use) { 0 }

        it 'returns 0 too' do
          expect(subject).to eq(0)
        end
      end
    end

    context 'with a trial plan' do
      let(:hosted_plan) { ultimate_plan }
      let(:trial) { true }

      it 'returns the current seats in use' do
        expect(subject).to eq(1)
      end

      it_behaves_like 'a disabled feature'
    end

    context 'with a free plan' do
      let(:hosted_plan) { free_plan }

      it 'returns the current seats in use' do
        expect(subject).to eq(1)
      end

      it_behaves_like 'a disabled feature'
    end
  end

  describe '#expired?' do
    let(:gitlab_subscription) { create(:gitlab_subscription, end_date: end_date) }

    subject { gitlab_subscription.expired? }

    context 'when end_date is expired' do
      let(:end_date) { Date.current.advance(days: -1) }

      it { is_expected.to be(true) }
    end

    context 'when end_date is not expired' do
      let(:end_date) { 1.week.from_now }

      it { is_expected.to be(false) }
    end

    context 'when end_date is nil' do
      let(:end_date) { nil }

      it { is_expected.to be(false) }
    end
  end

  describe '#has_a_paid_hosted_plan?' do
    using RSpec::Parameterized::TableSyntax

    let(:subscription) { build(:gitlab_subscription) }

    where(:plan_name, :seats, :result) do
      'bronze'        | 0 | false
      'bronze'        | 1 | true
      'premium'       | 1 | true
    end

    with_them do
      before do
        plan = build(:plan, name: plan_name)
        subscription.assign_attributes(hosted_plan: plan, seats: seats)
      end

      it 'returns true if subscription has a paid hosted plan' do
        expect(subscription.has_a_paid_hosted_plan?).to eq(result)
      end
    end
  end

  describe '#upgradable?' do
    using RSpec::Parameterized::TableSyntax

    let(:subscription) { build(:gitlab_subscription) }

    shared_examples 'upgradable lower plan' do |plan_name|
      where(:has_a_paid_hosted_plan, :expired, :result) do
        false | false | false
        true  | false | true
        true  | true  | false
        false | true  | false
      end

      with_them do
        before do
          plan = build(:plan, name: plan_name)
          allow(subscription).to receive(:expired?) { expired }
          allow(subscription).to receive(:has_a_paid_hosted_plan?) { has_a_paid_hosted_plan }
          subscription.assign_attributes(hosted_plan: plan)
        end

        it 'returns true if subscription is upgradable' do
          expect(subscription.upgradable?).to eq(result)
        end
      end
    end

    shared_examples 'top plan' do |plan_name|
      where(:has_a_paid_hosted_plan, :expired) do
        false | false
        true  | false
        true  | true
        false | true
      end

      with_them do
        before do
          plan = build(:plan, name: plan_name)
          allow(subscription).to receive(:expired?) { expired }
          allow(subscription).to receive(:has_a_paid_hosted_plan?) { has_a_paid_hosted_plan }
          subscription.assign_attributes(hosted_plan: plan)
        end

        it 'returns false' do
          expect(subscription.upgradable?).to eq(false)
        end
      end
    end

    (::Plan.all_plans - ::Plan::TOP_PLANS).each do |plan_name|
      it_behaves_like 'upgradable lower plan', plan_name
    end

    ::Plan::TOP_PLANS.each do |plan_name|
      it_behaves_like 'top plan', plan_name
    end
  end

  describe 'callbacks' do
    context 'after_commit', :saas do
      context 'index_namespace' do
        let_it_be(:namespace) { create(:namespace) }

        let(:gitlab_subscription) { build(:gitlab_subscription, plan, namespace: namespace) }
        let(:expiration_date) { Date.today + 10 }
        let(:plan) { :bronze }

        before do
          gitlab_subscription.end_date = expiration_date
        end

        it 'indexes the namespace' do
          expect(ElasticsearchIndexedNamespace).to receive(:safe_find_or_create_by!).with(namespace_id: gitlab_subscription.namespace_id)

          gitlab_subscription.save!
        end

        context 'when seats is 0' do
          let(:gitlab_subscription) { build(:gitlab_subscription, namespace: namespace, seats: 0) }

          it 'does not index the namespace' do
            expect(ElasticsearchIndexedNamespace).not_to receive(:safe_find_or_create_by!)

            gitlab_subscription.save!
          end
        end

        context 'when it is a trial' do
          let(:seats) { 10 }
          let(:gitlab_subscription) { build(:gitlab_subscription, :active_trial, namespace: namespace, seats: seats) }

          it 'indexes the namespace' do
            expect(ElasticsearchIndexedNamespace).to receive(:safe_find_or_create_by!).with(namespace_id: gitlab_subscription.namespace_id)

            gitlab_subscription.save!
          end

          context 'when seats is zero' do
            let(:seats) { 0 }

            it 'indexes the namespace' do
              expect(ElasticsearchIndexedNamespace).to receive(:safe_find_or_create_by!).with(namespace_id: gitlab_subscription.namespace_id)

              gitlab_subscription.save!
            end
          end

          context 'when in free plan' do
            let(:gitlab_subscription) { build(:gitlab_subscription, :active_trial, namespace: namespace, seats: seats, hosted_plan_id: nil) }

            it 'does not index the namespace' do
              expect(ElasticsearchIndexedNamespace).not_to receive(:safe_find_or_create_by!)

              gitlab_subscription.save!
            end
          end
        end

        context 'when not ::Gitlab.com?' do
          before do
            allow(::Gitlab).to receive(:com?).and_return(false)
          end

          it 'does not index the namespace' do
            expect(ElasticsearchIndexedNamespace).not_to receive(:safe_find_or_create_by!)

            gitlab_subscription.save!
          end
        end

        context 'when the plan has expired' do
          let(:expiration_date) { Date.today - 8.days }

          it 'does not index the namespace' do
            expect(ElasticsearchIndexedNamespace).not_to receive(:safe_find_or_create_by!)

            gitlab_subscription.save!
          end
        end

        context 'when it is a free plan' do
          let(:plan) { :free }

          it 'does not index the namespace' do
            expect(ElasticsearchIndexedNamespace).not_to receive(:safe_find_or_create_by!)

            gitlab_subscription.save!
          end
        end
      end
    end

    it 'has all attributes listed in the subscription history table' do
      expect(described_class.attribute_names)
        .to contain_exactly(
          *GitlabSubscriptionHistory::PREFIXED_ATTRIBUTES,
          *GitlabSubscriptionHistory::TRACKED_ATTRIBUTES,
          *GitlabSubscriptionHistory::OMITTED_ATTRIBUTES
        )
    end

    context 'before_update', :freeze_time do
      let(:gitlab_subscription) do
        create(
          :gitlab_subscription,
          seats_in_use: 20,
          max_seats_used: 42,
          max_seats_used_changed_at: 1.month.ago,
          seats: 13,
          seats_owed: 29,
          start_date: Date.today - 1.year
        )
      end

      context 'when a tracked attribute is updated' do
        it 'logs previous state to gitlab subscription history' do
          gitlab_subscription.update!(max_seats_used: 32)

          expect(GitlabSubscriptionHistory.count).to eq(1)
          expect(GitlabSubscriptionHistory.last.attributes).to include(
            'gitlab_subscription_id' => gitlab_subscription.id,
            'change_type' => 'gitlab_subscription_updated',
            'max_seats_used' => 42,
            'seats' => 13
          )
        end
      end

      context 'when tracked attributes are not updated' do
        it 'does not log previous state to gitlab subscription history' do
          expect do
            gitlab_subscription.update!(last_seat_refresh_at: Time.current)
          end.to not_change(GitlabSubscriptionHistory, :count)
        end
      end

      context 'when max_seats_used has changed' do
        it 'updates the max_seats_used_changed_at' do
          expect { gitlab_subscription.update!(max_seats_used: 52) }
            .to change(gitlab_subscription, :max_seats_used_changed_at)
            .to(be_like_time(Time.current))
        end
      end

      context 'when max_seats_used has not changed' do
        it 'does not change the max_seats_used_changed_at' do
          expect { gitlab_subscription.update!(max_seats_used: 42, seats_in_use: 25) }
            .to not_change(gitlab_subscription, :max_seats_used_changed_at)
        end
      end

      shared_examples 'resets seats' do
        it 'resets seats attributes' do
          expect do
            gitlab_subscription.update!(start_date: new_start, end_date: new_end)
          end.to change(gitlab_subscription, :max_seats_used).from(42).to(1)
            .and change(gitlab_subscription, :seats_owed).from(29).to(0)
            .and change(gitlab_subscription, :seats_in_use).from(20).to(1)

          expect(gitlab_subscription.max_seats_used_changed_at).to be_like_time(Time.current)
        end
      end

      context 'when starting a new term' do
        let(:new_start) { Date.today + 1.year }
        let(:new_end) { new_start + 1.year }

        context 'when start_date is after the old end_date' do
          let(:new_start) { gitlab_subscription.end_date + 1.year }
          let(:new_end) { new_start + 1.year }

          it_behaves_like 'resets seats'

          it 'triggers subscription started event' do
            expect { gitlab_subscription.update!(start_date: new_start, end_date: new_end) }
              .to publish_event(GitlabSubscriptions::RenewedEvent)
              .with(namespace_id: gitlab_subscription.namespace_id)
          end
        end

        context 'when the end_date was nil' do
          before do
            gitlab_subscription.update!(end_date: nil)
          end

          it_behaves_like 'resets seats'
        end

        context 'when the start_date is before the old end_date' do
          let(:new_start) { gitlab_subscription.end_date - 1.month }

          it_behaves_like 'resets seats'
        end

        context 'when max_seats_used_changed_at is not set' do
          before do
            gitlab_subscription.update!(max_seats_used_changed_at: nil)
          end

          it_behaves_like 'resets seats'
        end
      end

      context 'when dates are changed but not for a new term' do
        it 'does not reset seats attributes' do
          new_start_date = (gitlab_subscription.max_seats_used_changed_at - 1.day).to_date

          expect do
            gitlab_subscription.update!(start_date: new_start_date)
          end.to change(gitlab_subscription, :start_date).to(new_start_date)
            .and not_change(gitlab_subscription, :max_seats_used)
            .and not_change(gitlab_subscription, :max_seats_used_changed_at)
            .and not_change(gitlab_subscription, :seats_owed)
        end

        it 'does not trigger subscription started event' do
          expect(Gitlab::EventStore).not_to receive(:publish)

          gitlab_subscription.update!(start_date: Date.today)
        end
      end

      context 'when no dates are changed' do
        it 'does not reset seats attributes' do
          expect do
            gitlab_subscription.update!(seats_in_use: 99)
          end.to not_change(gitlab_subscription, :max_seats_used)
            .and not_change(gitlab_subscription, :max_seats_used_changed_at)
            .and not_change(gitlab_subscription, :seats_owed)
        end
      end

      context 'when max_seats_used_changed_at is not set' do
        it 'does not reset seats attributes' do
          gitlab_subscription.update!(max_seats_used_changed_at: nil)

          expect do
            gitlab_subscription.update!(seats_in_use: 99)
          end.to not_change(gitlab_subscription, :max_seats_used)
            .and not_change(gitlab_subscription, :max_seats_used_changed_at)
            .and not_change(gitlab_subscription, :seats_owed)
        end
      end

      context 'when max_seats_used_changed_at is on the start_date' do
        let(:new_start) { Date.today }
        let(:new_end) { new_start + 1.year }

        before do
          gitlab_subscription.update!(max_seats_used_changed_at: Time.current)
        end

        it 'does not reset seats attributes' do
          expect do
            gitlab_subscription.update!(seats_in_use: 99)
          end.to not_change(gitlab_subscription, :max_seats_used)
            .and not_change(gitlab_subscription, :max_seats_used_changed_at)
            .and not_change(gitlab_subscription, :seats_owed)
        end
      end

      context 'when max_seats_used_changed_at is before the start_date' do
        let(:new_start) { Date.today }
        let(:new_end) { new_start + 1.year }

        before do
          gitlab_subscription.update!(max_seats_used_changed_at: Time.current - 1.day)
        end

        it_behaves_like 'resets seats'
      end

      context 'with an active trial' do
        let_it_be(:trial_subscription) do
          create(:gitlab_subscription, hosted_plan: ultimate_plan, trial: true, max_seats_used: 10, seats_owed: 0, seats_in_use: 5)
        end

        it 'resets seats when upgrading to a paid plan' do
          expect do
            trial_subscription.update!(trial: false)
          end.to change(trial_subscription, :max_seats_used).from(10).to(1)
            .and not_change(trial_subscription, :seats_owed)
            .and not_change(trial_subscription, :seats_in_use)

          expect(trial_subscription.max_seats_used_changed_at).to be_like_time(Time.current)
        end

        it 'does not reset seats when downgrading to a free plan' do
          expect do
            trial_subscription.update!(trial: false, hosted_plan: free_plan)
          end.to not_change(trial_subscription, :max_seats_used)
            .and not_change(trial_subscription, :max_seats_used_changed_at)
        end
      end

      context 'when starting a trial with an expired subscription' do
        let(:new_start) { Date.today }
        let(:new_end) { new_start + 1.year }
        let(:max_seats_used_changed_at) { nil }
        let(:gitlab_subscription) do
          create(
            :gitlab_subscription,
            hosted_plan: ultimate_plan,
            start_date: Date.current - 2.years,
            end_date: Date.current - 1.year,
            max_seats_used_changed_at: max_seats_used_changed_at
          )
        end

        shared_examples 'does not reset seat statistics' do
          it 'does not reset seat statistics' do
            expect do
              gitlab_subscription.update!(trial: true, start_date: new_start, end_date: new_end)
            end.to not_change(gitlab_subscription, :max_seats_used)
              .and not_change(gitlab_subscription, :max_seats_used_changed_at)
              .and not_change(gitlab_subscription, :seats_owed)
          end
        end

        context 'when max_seats_used_changed_at has never been set' do
          it_behaves_like 'does not reset seat statistics'
        end

        context 'when max_seats_used_changed_at has been set' do
          let(:max_seats_used_changed_at) { Time.current - 1.year }

          it_behaves_like 'does not reset seat statistics'
        end
      end
    end

    context 'after_destroy_commit' do
      it 'logs previous state to gitlab subscription history' do
        group = create(:group)
        subject.update! max_seats_used: 37, seats: 11, namespace: group, hosted_plan: bronze_plan
        db_created_at = described_class.last.created_at

        subject.destroy!

        expect(GitlabSubscriptionHistory.count).to eq(1)
        expect(GitlabSubscriptionHistory.last.attributes).to include(
          'gitlab_subscription_id' => subject.id,
          'change_type' => 'gitlab_subscription_destroyed',
          'max_seats_used' => 37,
          'seats' => 11,
          'namespace_id' => group.id,
          'hosted_plan_id' => bronze_plan.id,
          'gitlab_subscription_created_at' => db_created_at
        )
      end
    end
  end

  describe '.yield_long_expired_indexed_namespaces' do
    let_it_be(:not_expired_subscription1) { create(:gitlab_subscription, :bronze, end_date: Date.today + 2) }
    let_it_be(:not_expired_subscription2) { create(:gitlab_subscription, :bronze, end_date: Date.today + 100) }
    let_it_be(:recently_expired_subscription) { create(:gitlab_subscription, :bronze, end_date: Date.today - 4) }
    let_it_be(:expired_subscription1) { create(:gitlab_subscription, :bronze, end_date: Date.today - 31) }
    let_it_be(:expired_subscription2) { create(:gitlab_subscription, :bronze, end_date: Date.today - 40) }

    before do
      allow(::Gitlab).to receive(:com?).and_return(true)
      ElasticsearchIndexedNamespace.safe_find_or_create_by!(namespace_id: not_expired_subscription1.namespace_id)
      ElasticsearchIndexedNamespace.safe_find_or_create_by!(namespace_id: not_expired_subscription2.namespace_id)
      ElasticsearchIndexedNamespace.safe_find_or_create_by!(namespace_id: recently_expired_subscription.namespace_id)
      ElasticsearchIndexedNamespace.safe_find_or_create_by!(namespace_id: expired_subscription1.namespace_id)
      ElasticsearchIndexedNamespace.safe_find_or_create_by!(namespace_id: expired_subscription2.namespace_id)
    end

    it 'yields ElasticsearchIndexedNamespace that belong to subscriptions that expired over a week ago' do
      results = []

      described_class.yield_long_expired_indexed_namespaces do |result|
        results << result
      end

      expect(results).to contain_exactly(
        expired_subscription1.namespace.elasticsearch_indexed_namespace,
        expired_subscription2.namespace.elasticsearch_indexed_namespace
      )
    end
  end

  describe '#trial_extended_or_reactivated?' do
    let_it_be(:gitlab_subscription, reload: true) { create(:gitlab_subscription, :active_trial) }

    before do
      gitlab_subscription.trial_extension_type = trial_extension_type
    end

    subject { gitlab_subscription.trial_extended_or_reactivated? }

    where(:trial_extension_type, :extended_or_reactivated) do
      nil | false
      1 | true
      2 | true
    end

    with_them do
      it { is_expected.to be(extended_or_reactivated) }
    end
  end

  describe '#legacy?' do
    let_it_be(:eoa_rollout_date) { GitlabSubscription::EOA_ROLLOUT_DATE.to_date }

    let!(:gitlab_subscription) { create(:gitlab_subscription, start_date: start_date) }

    subject { gitlab_subscription.legacy? }

    context 'when a subscription was purchased before the EoA rollout date' do
      let(:start_date) { eoa_rollout_date - 1.day }

      it { is_expected.to be_truthy }
    end

    context 'when a subscription was purchased on the EoA rollout date' do
      let(:start_date) { eoa_rollout_date }

      it { is_expected.to be_falsey }
    end

    context 'when a subscription was purchased after the EoA rollout date' do
      let(:start_date) { eoa_rollout_date + 1.day }

      it { is_expected.to be_falsey }
    end
  end
end
