# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscription do
  using RSpec::Parameterized::TableSyntax

  %i[free_plan bronze_plan premium_plan ultimate_plan].each do |plan|
    let_it_be(plan) { create(plan) }
  end

  describe 'default values' do
    it do
      travel_to(Date.today + 30) do
        expect(subject.start_date).to eq(Date.today)
      end
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
    let!(:gitlab_subscription) { create(:gitlab_subscription, subscription_attrs) }

    before do
      gitlab_subscription.update!(seats: 5, max_seats_used: 10)
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

  describe '#refresh_seat_attributes!' do
    subject { create(:gitlab_subscription, seats: 3, max_seats_used: 2) }

    before do
      expect(subject).to receive(:calculate_seats_in_use).and_return(calculate_seats_in_use)
    end

    context 'when current seats in use is lower than recorded max_seats_used' do
      let(:calculate_seats_in_use) { 1 }

      it 'does not increase max_seats_used' do
        expect do
          subject.refresh_seat_attributes!
        end.to change(subject, :seats_in_use).from(0).to(1)
          .and not_change(subject, :max_seats_used)
          .and not_change(subject, :seats_owed)
      end
    end

    context 'when current seats in use is higher than seats and max_seats_used' do
      let(:calculate_seats_in_use) { 4 }

      it 'increases seats and max_seats_used' do
        expect do
          subject.refresh_seat_attributes!
        end.to change(subject, :seats_in_use).from(0).to(4)
          .and change(subject, :max_seats_used).from(2).to(4)
          .and change(subject, :seats_owed).from(0).to(1)
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

    where(:plan_name, :paid_hosted_plan, :expired, :result) do
      'bronze'   | true | false  | true
      'bronze'   | true | true   | false
      'premium'  | true | false  | true
      'ultimate' | true | false  | false
    end

    with_them do
      before do
        plan = build(:plan, name: plan_name)
        allow(subscription).to receive(:expired?) { expired }
        allow(subscription).to receive(:has_a_paid_hosted_plan?) { paid_hosted_plan }
        subscription.assign_attributes(hosted_plan: plan)
      end

      it 'returns true if subscription is upgradable' do
        expect(subscription.upgradable?).to eq(result)
      end
    end
  end

  describe 'callbacks' do
    context 'after_commit :index_namespace' do
      let_it_be(:namespace) { create(:namespace) }

      let(:gitlab_subscription) { build(:gitlab_subscription, plan, namespace: namespace) }
      let(:dev_env_or_com) { true }
      let(:expiration_date) { Date.today + 10 }
      let(:plan) { :bronze }

      before do
        allow(::Gitlab).to receive(:dev_env_or_com?).and_return(dev_env_or_com)
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

      context 'when not ::Gitlab.dev_env_or_com?' do
        let(:dev_env_or_com) { false }

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

    it 'gitlab_subscription columns are contained in gitlab_subscription_history columns' do
      diff_attrs = %w(updated_at seats_in_use seats_owed)
      expect(described_class.attribute_names - GitlabSubscriptionHistory.attribute_names).to eq(diff_attrs)
    end

    it 'gitlab_subscription_history columns have some extra columns over gitlab_subscription' do
      diff_attrs = %w(gitlab_subscription_created_at gitlab_subscription_updated_at change_type gitlab_subscription_id)
      expect(GitlabSubscriptionHistory.attribute_names - described_class.attribute_names).to eq(diff_attrs)
    end

    context 'before_update' do
      it 'logs previous state to gitlab subscription history' do
        gitlab_subscription = create(:gitlab_subscription, max_seats_used: 42, seats: 13, namespace: create(:namespace))

        gitlab_subscription.update! max_seats_used: 32

        expect(GitlabSubscriptionHistory.count).to eq(1)
        expect(GitlabSubscriptionHistory.last.attributes).to include(
          'gitlab_subscription_id' => gitlab_subscription.id,
          'change_type' => 'gitlab_subscription_updated',
          'max_seats_used' => 42,
          'seats' => 13
        )
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
    let_it_be(:expired_subscription1) { create(:gitlab_subscription, :bronze, end_date: Date.today - 8) }
    let_it_be(:expired_subscription2) { create(:gitlab_subscription, :bronze, end_date: Date.today - 10) }

    before do
      allow(::Gitlab).to receive(:dev_env_or_com?).and_return(true)
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

  context 'when in a trial' do
    let_it_be(:gitlab_subscription, reload: true) { create(:gitlab_subscription, :active_trial) }

    let(:start_trial_on) { nil }
    let(:end_trial_on) { nil }
    let(:trial_extension_type) { nil }

    before do
      gitlab_subscription.trial_starts_on = start_trial_on if start_trial_on
      gitlab_subscription.trial_ends_on = end_trial_on if end_trial_on
      gitlab_subscription.trial_extension_type = trial_extension_type
    end

    describe '#trial_extended_or_reactivated?' do
      subject { gitlab_subscription.trial_extended_or_reactivated? }

      where(:trial_extension_type, :extended_or_reactivated) do
        nil | false
        1   | true
        2   | true
      end

      with_them do
        it { is_expected.to be(extended_or_reactivated) }
      end
    end

    describe '#trial_days_remaining' do
      subject { gitlab_subscription.trial_days_remaining }

      context 'at the beginning of a trial' do
        let(:start_trial_on) { Date.current }
        let(:end_trial_on) { Date.current.advance(days: 30) }

        it { is_expected.to eq(30) }
      end

      context 'in the middle of a trial' do
        it { is_expected.to eq(15) }
      end

      context 'at the end of a trial' do
        let(:start_trial_on) { Date.current.advance(days: -30) }
        let(:end_trial_on) { Date.current }

        it { is_expected.to eq(0) }
      end
    end

    describe '#trial_duration' do
      subject { gitlab_subscription.trial_duration }

      context 'for a default trial duration' do
        it { is_expected.to eq(30) }
      end

      context 'for a custom trial duration' do
        let(:start_trial_on) { Date.current.advance(days: -5) }
        let(:end_trial_on) { Date.current.advance(days: 5) }

        it { is_expected.to eq(10) }
      end
    end

    describe '#trial_days_used' do
      subject { gitlab_subscription.trial_days_used }

      context 'at the beginning of a trial' do
        let(:start_trial_on) { Date.current }
        let(:end_trial_on) { Date.current.advance(days: 30) }

        it { is_expected.to eq(0) }
      end

      context 'in the middle of a trial' do
        it { is_expected.to eq(15) }
      end

      context 'at the end of a trial' do
        let(:start_trial_on) { Date.current.advance(days: -30) }
        let(:end_trial_on) { Date.current }

        it { is_expected.to eq(30) }
      end
    end

    describe '#trial_percentage_complete' do
      subject { gitlab_subscription.trial_percentage_complete }

      context 'at the beginning of a trial' do
        let(:start_trial_on) { Date.current }
        let(:end_trial_on) { Date.current.advance(days: 30) }

        it { is_expected.to eq(0.0) }
      end

      context 'in the middle of a trial' do
        it { is_expected.to eq(50.0) }
      end

      context 'at the end of a trial' do
        let(:start_trial_on) { Date.current.advance(days: -30) }
        let(:end_trial_on) { Date.current }

        it { is_expected.to eq(100.0) }
      end

      context 'rounding' do
        let(:start_trial_on) { Date.current.advance(days: -10) }
        let(:end_trial_on) { Date.current.advance(days: 20) }

        context 'by default' do
          it 'rounds to 2 decimal places' do
            is_expected.to eq(33.33)
          end
        end

        context 'with custom rounding options' do
          subject { gitlab_subscription.trial_percentage_complete(4) }

          it 'rounds to the given number of decimal places' do
            is_expected.to eq(33.3333)
          end
        end
      end
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
      let(:start_date) { eoa_rollout_date + 1.day}

      it { is_expected.to be_falsey }
    end
  end
end
