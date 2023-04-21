# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BillingPlansHelper, :saas, feature_category: :subscription_management do
  include Devise::Test::ControllerHelpers

  describe '#subscription_plan_data_attributes' do
    let(:group) { build(:group) }
    let(:customer_portal_url) { Gitlab::SubscriptionPortal::SUBSCRIPTIONS_MANAGE_URL }
    let(:add_seats_href) { "#{EE::SUBSCRIPTIONS_URL}/gitlab/namespaces/#{group.id}/extra_seats" }
    let(:plan_renew_href) { "#{EE::SUBSCRIPTIONS_URL}/gitlab/namespaces/#{group.id}/renew" }
    let(:billable_seats_href) { helper.group_usage_quotas_path(group, anchor: 'seats-quota-tab') }
    let(:refresh_seats_href) { helper.refresh_seats_group_billings_url(group) }
    let(:read_only) { true }

    let(:plan) do
      double('plan', id: 'external-paid-plan-hash-code', name: 'Bronze Plan')
    end

    context 'when group and plan with ID present' do
      let(:base_attrs) do
        {
          namespace_id: group.id,
          namespace_name: group.name,
          add_seats_href: add_seats_href,
          plan_renew_href: plan_renew_href,
          customer_portal_url: customer_portal_url,
          billable_seats_href: billable_seats_href,
          plan_name: plan.name,
          read_only: read_only.to_s,
          seats_last_updated: nil
        }
      end

      it 'returns data attributes' do
        expect(helper.subscription_plan_data_attributes(group, plan, read_only: read_only))
          .to eq(base_attrs.merge(refresh_seats_href: refresh_seats_href))
      end

      context 'with refresh_billings_seats feature flag off' do
        before do
          stub_feature_flags(refresh_billings_seats: false)
        end

        it 'returns data attributes' do
          expect(helper.subscription_plan_data_attributes(group, plan, read_only: read_only))
            .to eq(base_attrs)
        end
      end
    end

    context 'when group not present' do
      let(:group) { nil }

      it 'returns empty data attributes' do
        expect(helper.subscription_plan_data_attributes(group, plan, read_only: read_only)).to eq({})
      end
    end

    context 'when plan not present' do
      let(:plan) { nil }

      let(:base_attrs) do
        {
          add_seats_href: add_seats_href,
          billable_seats_href: billable_seats_href,
          customer_portal_url: customer_portal_url,
          namespace_id: nil,
          namespace_name: group.name,
          plan_renew_href: plan_renew_href,
          plan_name: nil,
          read_only: read_only.to_s,
          seats_last_updated: nil
        }
      end

      it 'returns attributes' do
        expect(helper.subscription_plan_data_attributes(group, plan, read_only: read_only))
          .to eq(base_attrs.merge(refresh_seats_href: refresh_seats_href))
      end

      context 'with refresh_billings_seats feature flag off' do
        before do
          stub_feature_flags(refresh_billings_seats: false)
        end

        it 'returns data attributes' do
          expect(helper.subscription_plan_data_attributes(group, plan, read_only: read_only))
            .to eq(base_attrs)
        end
      end
    end

    context 'when plan with ID not present' do
      let(:plan) { double('plan', id: nil, name: 'Bronze Plan') }

      let(:base_attrs) do
        {
          namespace_id: group.id,
          namespace_name: group.name,
          customer_portal_url: customer_portal_url,
          billable_seats_href: billable_seats_href,
          add_seats_href: add_seats_href,
          plan_renew_href: plan_renew_href,
          plan_name: plan.name,
          read_only: read_only.to_s,
          seats_last_updated: nil
        }
      end

      it 'returns data attributes without upgrade href' do
        expect(helper.subscription_plan_data_attributes(group, plan, read_only: read_only))
          .to eq(base_attrs.merge(refresh_seats_href: refresh_seats_href))
      end

      context 'with refresh_billings_seats feature flag off' do
        before do
          stub_feature_flags(refresh_billings_seats: false)
        end

        it 'returns data attributes' do
          expect(helper.subscription_plan_data_attributes(group, plan, read_only: read_only))
            .to eq(base_attrs)
        end
      end
    end

    context 'with different namespaces' do
      subject { helper.subscription_plan_data_attributes(namespace, plan) }

      context 'with namespace' do
        let(:namespace) { build(:namespace) }

        it 'does not return billable_seats_href' do
          expect(subject).not_to include(billable_seats_href: helper.group_usage_quotas_path(namespace, anchor: 'seats-quota-tab'))
        end
      end

      context 'with group' do
        let(:namespace) { build(:group) }

        it 'returns billable_seats_href for group' do
          expect(subject).to include(billable_seats_href: helper.group_usage_quotas_path(namespace, anchor: 'seats-quota-tab'))
        end
      end
    end

    context 'when seats_last_updated is being assigned' do
      let(:enqueue_time) { Time.new(2023, 2, 21, 12, 13, 14, "+00:00") }

      subject(:seats_last_updated) { helper.subscription_plan_data_attributes(group, plan, read_only: read_only)[:seats_last_updated] }

      context 'when the subscription has a last_seat_refresh_at' do
        let(:gitlab_subscription) { build(:gitlab_subscription, namespace: group, last_seat_refresh_at: enqueue_time) }

        before do
          allow(group).to receive(:gitlab_subscription).and_return(gitlab_subscription)
        end

        it { is_expected.to eq '12:13:14' }
      end

      context 'when no last_seat_refresh_at is available' do
        it { is_expected.to be nil }
      end
    end
  end

  describe '#use_new_purchase_flow?' do
    where type: [Group.sti_name, Namespaces::UserNamespace.sti_name],
      plan: Plan.all_plans,
      trial_active: [true, false]

    with_them do
      let_it_be(:user) { create(:user) }
      let(:namespace) { create(:namespace_with_plan, plan: "#{plan}_plan".to_sym, type: type) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(namespace).to receive(:trial_active?).and_return(trial_active)
      end

      subject { helper.use_new_purchase_flow?(namespace) }

      it do
        result = type == Group.sti_name && (plan == Plan::FREE || trial_active)

        is_expected.to be(result)
      end
    end

    context 'when the group is on a plan eligible for the new purchase flow' do
      let(:namespace) { create(:namespace_with_plan, plan: :free_plan, type: Group) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      context 'when the user has a last name' do
        let(:user) { build(:user, last_name: 'Lastname') }

        it 'returns true' do
          expect(helper.use_new_purchase_flow?(namespace)).to eq true
        end
      end

      context 'when the user does not have a last name' do
        let(:user) { build(:user, last_name: nil, name: 'Firstname') }

        it 'returns false' do
          expect(helper.use_new_purchase_flow?(namespace)).to eq false
        end
      end
    end
  end

  describe '#upgrade_offer_type' do
    using RSpec::Parameterized::TableSyntax

    let(:plan) { double('plan', { id: '123456789' }) }

    context 'when plan has a valid property' do
      where(:plan_name, :for_free, :plan_id, :result) do
        Plan::BRONZE | true | '123456789' | :upgrade_for_free
        Plan::BRONZE | true | '987654321' | :no_offer
        Plan::BRONZE | true | nil | :no_offer
        Plan::BRONZE | false | '123456789' | :upgrade_for_offer
        Plan::BRONZE | false | nil | :no_offer
        Plan::BRONZE | nil | nil | :no_offer
        Plan::PREMIUM | nil | nil | :no_offer
        nil | true | nil | :no_offer
      end

      with_them do
        let(:namespace) do
          double('plan', { actual_plan_name: plan_name, id: '000000000' })
        end

        before do
          allow_next_instance_of(GitlabSubscriptions::PlanUpgradeService) do |instance|
            expect(instance).to receive(:execute).once.and_return({
                                                                    upgrade_for_free: for_free,
                                                                    upgrade_plan_id: plan_id
                                                                  })
          end
        end

        subject { helper.upgrade_offer_type(namespace, plan) }

        it { is_expected.to eq(result) }
      end
    end
  end

  describe '#has_upgrade?' do
    using RSpec::Parameterized::TableSyntax

    where(:offer_type, :result) do
      :no_offer | false
      :upgrade_for_free | true
      :upgrade_for_offer | true
    end

    with_them do
      subject { helper.has_upgrade?(offer_type) }

      it { is_expected.to eq(result) }
    end
  end

  describe '#can_edit_billing?' do
    let(:group_with_flag) { build(:group) }
    let(:group_without_flag) { build(:group) }
    let(:auditor) { create(:auditor) }
    let(:dev) { create(:user) }

    describe 'when feature flag is set to true for group' do
      before do
        stub_feature_flags(auditor_billing_page_access: group_with_flag)

        group_with_flag.add_developer(dev)
        group_with_flag.add_guest(auditor)
      end

      it 'is true for auditor' do
        allow(helper).to receive(:current_user).and_return(auditor)

        expect(helper.can_edit_billing?(group_with_flag)).to eq(true)
      end

      it 'is false for developer' do
        allow(helper).to receive(:current_user).and_return(dev)

        expect(helper.can_edit_billing?(group_with_flag)).to eq(true)
      end
    end

    it 'is true for group without feature flag set' do
      stub_feature_flags(auditor_billing_page_access: false)
      expect(helper.can_edit_billing?(group_without_flag)).to eq(true)
    end
  end

  describe '#show_contact_sales_button?' do
    using RSpec::Parameterized::TableSyntax

    where(:link_action, :upgrade_offer, :result) do
      'upgrade' | :no_offer | true
      'upgrade' | :upgrade_for_free | false
      'upgrade' | :upgrade_for_offer | true
      'no_upgrade' | :no_offer | false
      'no_upgrade' | :upgrade_for_free | false
      'no_upgrade' | :upgrade_for_offer | false
    end

    with_them do
      subject { helper.show_contact_sales_button?(link_action, upgrade_offer) }

      it { is_expected.to eq(result) }
    end
  end

  describe '#show_upgrade_button?' do
    using RSpec::Parameterized::TableSyntax

    where(:link_action, :upgrade_offer, :allow_upgrade, :result) do
      'upgrade' | :no_offer             | true  | true
      'upgrade' | :upgrade_for_free     | true  | true
      'upgrade' | :upgrade_for_offer    | true  | false
      'upgrade' | :no_offer             | false | false
      'upgrade' | :upgrade_for_free     | false | false
      'upgrade' | :upgrade_for_offer    | false | false
      'upgrade' | :no_offer             | nil   | true
      'upgrade' | :upgrade_for_free     | nil   | true
      'upgrade' | :upgrade_for_offer    | nil   | false
      'no_upgrade' | :no_offer          | true  | false
      'no_upgrade' | :upgrade_for_free  | true  | false
      'no_upgrade' | :upgrade_for_offer | true  | false
      'no_upgrade' | :no_offer          | false | false
      'no_upgrade' | :upgrade_for_free  | false | false
      'no_upgrade' | :upgrade_for_offer | false | false
      'no_upgrade' | :no_offer          | nil   | false
      'no_upgrade' | :upgrade_for_free  | nil   | false
      'no_upgrade' | :upgrade_for_offer | nil   | false
    end

    with_them do
      subject { helper.show_upgrade_button?(link_action, upgrade_offer, allow_upgrade) }

      it { is_expected.to eq(result) }
    end
  end

  describe '#plan_feature_list' do
    let(:plan) do
      Hashie::Mash.new(features: (1..3).map { |i| { title: "feat 0#{i}", highlight: i.even? } })
    end

    it 'returns features list sorted by highlight attribute' do
      expect(helper.plan_feature_list(plan)).to eq([{ 'title' => 'feat 02', 'highlight' => true },
                                                    { 'title' => 'feat 01', 'highlight' => false },
                                                    { 'title' => 'feat 03', 'highlight' => false }])
    end
  end

  describe '#plan_purchase_or_upgrade_url' do
    let(:plan) { double('Plan') }

    it 'is upgradable' do
      group = double(Group.sti_name, upgradable?: true)

      expect(helper).to receive(:plan_upgrade_url)

      helper.plan_purchase_or_upgrade_url(group, plan)
    end

    it 'is purchasable' do
      group = double(Group.sti_name, upgradable?: false)

      expect(helper).to receive(:plan_purchase_url)
      helper.plan_purchase_or_upgrade_url(group, plan)
    end
  end

  describe '#plan_purchase_url' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }

    let(:plan) { double('Plan', id: '123456789', purchase_link: double('PurchaseLink', href: '987654321')) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'builds correct url with some source' do
      allow(helper).to receive(:use_new_purchase_flow?).and_return(true)
      allow(helper).to receive(:params).and_return({ source: 'some_source' })

      expect(helper).to receive(:new_subscriptions_path).with(plan_id: plan.id, namespace_id: group.id, source: 'some_source')

      helper.plan_purchase_url(group, plan)
    end

    it 'builds correct url for the old purchase flow' do
      allow(helper).to receive(:use_new_purchase_flow?).and_return(false)

      expect(helper.plan_purchase_url(group, plan)).to eq("#{plan.purchase_link.href}&gl_namespace_id=#{group.id}")
    end
  end

  describe '#hand_raise_props' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:user) { create(:user, username: 'Joe', first_name: 'Joe', last_name: 'Doe', organization: 'ACME') }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'builds correct hash' do
      props = helper.hand_raise_props(namespace, glm_content: 'some-content')
      expect(props).to eq(namespace_id: namespace.id, user_name: 'Joe', first_name: 'Joe', last_name: 'Doe', company_name: 'ACME', glm_content: 'some-content')
    end
  end

  describe '#free_plan_billing_hand_raise_props' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:user) { create(:user, username: 'Joe', first_name: 'Joe', last_name: 'Doe', organization: 'ACME') }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'builds correct hash' do
      props = helper.free_plan_billing_hand_raise_props(namespace, glm_content: 'some-content')

      expect(props.keys).to match_array([:namespace_id,
                                         :user_name,
                                         :first_name,
                                         :last_name,
                                         :company_name,
                                         :glm_content,
                                         :button_attributes,
                                         :button_text,
                                         :track_action,
                                         :track_label])
    end
  end

  describe '#upgrade_button_text' do
    using RSpec::Parameterized::TableSyntax

    subject { helper.upgrade_button_text(plan_offer_type) }

    where(:plan_offer_type, :result) do
      :no_offer | 'Upgrade'
      :upgrade_for_free | 'Upgrade for free'
      :upgrade_for_offer | 'Upgrade'
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '#upgrade_button_css_classes' do
    let(:plan) { double('Plan', deprecated?: plan_is_deprecated) }
    let(:namespace) { double('Namespace', trial_active?: trial_active) }

    subject { helper.upgrade_button_css_classes(namespace, plan, is_current_plan) }

    before do
      allow(helper).to receive(:use_new_purchase_flow?).and_return(use_new_purchase_flow)
    end

    where(
      is_current_plan: [true, false],
      trial_active: [true, false],
      plan_is_deprecated: [true, false],
      use_new_purchase_flow: [true, false]
    )

    with_them do
      it 'returns the expected list of CSS classes' do
        expected_classes = [].tap do |ary|
          ary << 'disabled' if is_current_plan && !trial_active
          ary << 'invisible' if plan_is_deprecated
          ary << "billing-cta-purchase#{'-new' if use_new_purchase_flow}"
        end.join(' ')

        is_expected.to eq(expected_classes)
      end
    end
  end

  describe '#billing_available_plans' do
    let(:plan) { double('Plan', deprecated?: false, code: 'premium', hide_deprecated_card?: false) }
    let(:deprecated_plan) { double('Plan', deprecated?: true, code: 'bronze', hide_deprecated_card?: false) }
    let(:plans_data) { [plan, deprecated_plan] }

    context 'when namespace is not on a plan' do
      it 'returns plans without deprecated' do
        expect(helper.billing_available_plans(plans_data, nil)).to eq([plan])
      end
    end

    context 'when namespace is on an active plan' do
      let(:current_plan) { double('plan', code: 'premium') }

      it 'returns plans without deprecated' do
        expect(helper.billing_available_plans(plans_data, nil)).to eq([plan])
      end
    end

    context 'when namespace is on a deprecated plan' do
      let(:current_plan) { double('plan', code: 'bronze') }

      it 'returns plans with a deprecated plan' do
        expect(helper.billing_available_plans(plans_data, current_plan)).to eq(plans_data)
      end
    end

    context 'when namespace is on a deprecated plan that has hide_deprecated_card set to true' do
      let(:current_plan) { double('plan', code: 'bronze') }
      let(:deprecated_plan) { double('Plan', deprecated?: true, code: 'bronze', hide_deprecated_card?: true) }

      it 'returns plans without the deprecated plan' do
        expect(helper.billing_available_plans(plans_data, current_plan)).to eq([plan])
      end
    end

    context 'when namespace is on a plan that has hide_deprecated_card set to true, but deprecated? is false' do
      let(:current_plan) { double('plan', code: 'premium') }
      let(:plan) { double('Plan', deprecated?: false, code: 'premium', hide_deprecated_card?: true) }

      it 'returns plans with the deprecated plan' do
        expect(helper.billing_available_plans(plans_data, current_plan)).to eq([plan])
      end
    end
  end

  describe '#subscription_plan_info' do
    it 'returns the current plan' do
      other_plan = Hashie::Mash.new(code: 'bronze')
      current_plan = Hashie::Mash.new(code: 'ultimate')

      expect(helper.subscription_plan_info([other_plan, current_plan], 'ultimate')).to eq(current_plan)
    end

    it 'returns nil if no plan matches the code' do
      plan_a = Hashie::Mash.new(code: 'bronze')
      plan_b = Hashie::Mash.new(code: 'ultimate')

      expect(helper.subscription_plan_info([plan_a, plan_b], 'default')).to be_nil
    end

    it 'breaks a tie with the current_subscription_plan attribute if multiple plans have the same code' do
      other_plan = Hashie::Mash.new(current_subscription_plan: false, code: 'premium')
      current_plan = Hashie::Mash.new(current_subscription_plan: true, code: 'premium')

      expect(helper.subscription_plan_info([other_plan, current_plan], 'premium')).to eq(current_plan)
    end

    it 'returns nil if no plan matches the code even if current_subscription_plan is true' do
      other_plan = Hashie::Mash.new(current_subscription_plan: false, code: 'free')
      current_plan = Hashie::Mash.new(current_subscription_plan: true, code: 'bronze')

      expect(helper.subscription_plan_info([other_plan, current_plan], 'default')).to be_nil
    end

    it 'returns the plan matching the plan code even if current_subscription_plan is false' do
      other_plan = Hashie::Mash.new(current_subscription_plan: false, code: 'bronze')
      current_plan = Hashie::Mash.new(current_subscription_plan: false, code: 'premium')

      expect(helper.subscription_plan_info([other_plan, current_plan], 'premium')).to eq(current_plan)
    end
  end

  describe '#show_plans?' do
    using RSpec::Parameterized::TableSyntax

    let(:group) { build(:group) }

    where(:free_personal, :trial_active, :gold_plan, :ultimate_plan, :opensource_plan, :expectations) do
      false | false | false | false | false | true
      false | true | false | false | false | true
      false | false | true | false | false | false
      false | true | true | false | false | true
      false | false | false | true | false | false
      false | true | false | true | false | true
      false | false | true | true | false | false
      false | true | true | true | false | true
      true | true | true | true | false | false
      false | false | false | false | true | false
    end

    with_them do
      before do
        allow(group).to receive(:free_personal?).and_return(free_personal)
        allow(group).to receive(:trial_active?).and_return(trial_active)
        allow(group).to receive(:gold_plan?).and_return(gold_plan)
        allow(group).to receive(:ultimate_plan?).and_return(ultimate_plan)
        allow(group).to receive(:opensource_plan?).and_return(opensource_plan)
      end

      it 'returns boolean' do
        expect(helper.show_plans?(group)).to eql(expectations)
      end
    end
  end

  describe '#show_start_free_trial_messages?' do
    using RSpec::Parameterized::TableSyntax

    let(:namespace) { build(:namespace) }

    where(:free_personal, :eligible_for_trial, :expected) do
      false | true | true
      true | true | false
      false | false | false
    end

    with_them do
      before do
        allow(namespace).to receive(:free_personal?).and_return(free_personal)
        allow(namespace).to receive(:eligible_for_trial?).and_return(eligible_for_trial)
      end

      it 'returns correct boolean value' do
        expect(helper.show_start_free_trial_messages?(namespace)).to eql(expected)
      end
    end
  end

  describe '#billing_upgrade_button_data' do
    let(:plan) { double('Plan', code: '_code_') }
    let(:data) do
      {
        track_action: 'click_button',
        track_label: 'upgrade',
        track_property: plan.code,
        qa_selector: "upgrade_to_#{plan.code}"
      }
    end

    it 'has expected data' do
      expect(helper.billing_upgrade_button_data(plan)).to eq data
    end
  end

  describe '#start_free_trial_data' do
    let(:data) do
      {
        track_action: 'click_button',
        track_label: 'start_trial',
        qa_selector: 'start_your_free_trial'
      }
    end

    it 'has expected data' do
      expect(helper.start_free_trial_data).to eq data
    end
  end

  describe '#add_namespace_plan_to_group_instructions' do
    let_it_be(:current_user) { create :user }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    context 'with maintained or owned group' do
      it 'instructs to move the project to a group' do
        create(:group).add_owner current_user

        expect(helper.add_namespace_plan_to_group_instructions).to eq 'You&#39;ll have to <a href="/help/user/project/settings/index#transfer-a-project-to-another-namespace" target="_blank" rel="noopener noreferrer">move this project</a> to one of your groups.'
      end
    end

    context 'without a group' do
      it 'instructs to create a group then move the project to a group' do
        expect(helper.add_namespace_plan_to_group_instructions).to eq 'You don&#39;t have any groups. You&#39;ll need to <a href="/groups/new#create-group-pane">create one</a> and <a href="/help/user/project/settings/index#transfer-a-project-to-another-namespace" target="_blank" rel="noopener noreferrer">move this project to it</a>.'
      end
    end
  end
end
