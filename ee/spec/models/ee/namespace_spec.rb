# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace do
  using RSpec::Parameterized::TableSyntax

  include EE::GeoHelpers

  let(:namespace) { create(:namespace) }
  let(:default_plan) { create(:default_plan) }
  let(:free_plan) { create(:free_plan) }
  let!(:bronze_plan) { create(:bronze_plan) }
  let!(:premium_plan) { create(:premium_plan) }
  let!(:ultimate_plan) { create(:ultimate_plan) }

  it { is_expected.to have_one(:namespace_statistics) }
  it { is_expected.to have_one(:namespace_limit) }
  it { is_expected.to have_one(:elasticsearch_indexed_namespace) }
  it { is_expected.to have_one :upcoming_reconciliation }
  it { is_expected.to have_many(:ci_minutes_additional_packs) }

  it { is_expected.to delegate_method(:shared_runners_seconds).to(:namespace_statistics) }
  it { is_expected.to delegate_method(:shared_runners_seconds_last_reset).to(:namespace_statistics) }
  it { is_expected.to delegate_method(:trial?).to(:gitlab_subscription) }
  it { is_expected.to delegate_method(:trial_ends_on).to(:gitlab_subscription) }
  it { is_expected.to delegate_method(:trial_starts_on).to(:gitlab_subscription) }
  it { is_expected.to delegate_method(:trial_days_remaining).to(:gitlab_subscription) }
  it { is_expected.to delegate_method(:trial_percentage_complete).to(:gitlab_subscription) }
  it { is_expected.to delegate_method(:upgradable?).to(:gitlab_subscription) }
  it { is_expected.to delegate_method(:trial_extended_or_reactivated?).to(:gitlab_subscription) }
  it { is_expected.to delegate_method(:email).to(:owner).with_prefix.allow_nil }
  it { is_expected.to delegate_method(:additional_purchased_storage_size).to(:namespace_limit) }
  it { is_expected.to delegate_method(:additional_purchased_storage_size=).to(:namespace_limit).with_arguments(:args) }
  it { is_expected.to delegate_method(:additional_purchased_storage_ends_on).to(:namespace_limit) }
  it { is_expected.to delegate_method(:additional_purchased_storage_ends_on=).to(:namespace_limit).with_arguments(:args) }
  it { is_expected.to delegate_method(:temporary_storage_increase_ends_on).to(:namespace_limit) }
  it { is_expected.to delegate_method(:temporary_storage_increase_ends_on=).to(:namespace_limit).with_arguments(:args) }
  it { is_expected.to delegate_method(:temporary_storage_increase_enabled?).to(:namespace_limit) }
  it { is_expected.to delegate_method(:eligible_for_temporary_storage_increase?).to(:namespace_limit) }

  shared_examples 'plan helper' do |namespace_plan|
    let(:namespace) { create(:namespace_with_plan, plan: "#{plan_name}_plan") }

    subject { namespace.public_send("#{namespace_plan}_plan?") }

    context "for a #{namespace_plan} plan" do
      let(:plan_name) { namespace_plan }

      it { is_expected.to eq(true) }
    end

    context "for a plan that isn't #{namespace_plan}" do
      where(plan_name: described_class::PLANS - [namespace_plan])

      with_them do
        it { is_expected.to eq(false) }
      end
    end
  end

  described_class::PLANS.each do |namespace_plan|
    describe "#{namespace_plan}_plan?" do
      it_behaves_like 'plan helper', namespace_plan
    end
  end

  describe '#free_personal?' do
    where(:user, :paid, :expected) do
      true  | false | true
      false | false | false
      false | true  | false
    end

    with_them do
      before do
        allow(namespace).to receive(:user?).and_return(user)
        allow(namespace).to receive(:paid?).and_return(paid)
      end

      it 'returns expected boolean value' do
        expect(namespace.free_personal?).to eq(expected)
      end
    end
  end

  describe '#use_elasticsearch?' do
    let(:namespace) { create :namespace }

    it 'returns false if elasticsearch indexing is disabled' do
      stub_ee_application_setting(elasticsearch_indexing: false)

      expect(namespace.use_elasticsearch?).to eq(false)
    end

    it 'returns true if elasticsearch indexing enabled but limited indexing disabled' do
      stub_ee_application_setting(elasticsearch_indexing: true, elasticsearch_limit_indexing: false)

      expect(namespace.use_elasticsearch?).to eq(true)
    end

    it 'returns true if it is enabled specifically' do
      stub_ee_application_setting(elasticsearch_indexing: true, elasticsearch_limit_indexing: true)

      expect(namespace.use_elasticsearch?).to eq(false)

      create :elasticsearch_indexed_namespace, namespace: namespace

      expect(namespace.use_elasticsearch?).to eq(true)
    end
  end

  describe '#actual_plan_name' do
    let(:namespace) { create(:namespace) }

    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    subject { namespace.actual_plan_name }

    context 'when DB is read-only' do
      before do
        expect(Gitlab::Database).to receive(:read_only?) { true }
      end

      it 'returns free plan' do
        is_expected.to eq('free')
      end

      it 'does not create a gitlab_subscription' do
        expect { subject }.not_to change(GitlabSubscription, :count)
      end
    end

    context 'when namespace is not persisted' do
      let(:namespace) { build(:namespace) }

      it 'returns free plan' do
        is_expected.to eq('free')
      end

      it 'does not create a gitlab_subscription' do
        expect { subject }.not_to change(GitlabSubscription, :count)
      end
    end

    context 'when DB is not read-only' do
      it 'returns free plan' do
        is_expected.to eq('free')
      end

      it 'creates a gitlab_subscription' do
        expect { subject }.to change(GitlabSubscription, :count).by(1)
      end
    end
  end

  context 'scopes' do
    describe '.with_feature_available_in_plan' do
      let!(:namespace) { create(:namespace) }

      context 'plan is nil' do
        it 'returns no namespace' do
          expect(described_class.with_feature_available_in_plan(:group_project_templates)).to be_empty
        end
      end

      context 'plan is set' do
        it 'returns namespaces with plan' do
          create(:gitlab_subscription, :bronze, namespace: namespace)
          create(:namespace_with_plan, plan: :free_plan)

          expect(described_class.with_feature_available_in_plan(:audit_events)).to eq([namespace])
        end
      end
    end

    describe '.join_gitlab_subscription' do
      let!(:namespace) { create(:namespace) }

      subject { described_class.join_gitlab_subscription.select('gitlab_subscriptions.hosted_plan_id').first.hosted_plan_id }

      context 'when there is no subscription' do
        it 'returns namespace with nil subscription' do
          is_expected.to be_nil
        end
      end

      context 'when there is a subscription' do
        let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan_id: ultimate_plan.id) }

        it 'returns namespace with subscription set' do
          is_expected.to eq(ultimate_plan.id)
        end
      end
    end

    describe '.in_active_trial' do
      let_it_be(:namespaces) do
        [
            create(:namespace),
            create(:namespace_with_plan),
            create(:namespace_with_plan, trial_ends_on: Date.tomorrow)
        ]
      end

      it 'is consistent to trial_active? method' do
        namespaces.each do |ns|
          consistent = described_class.in_active_trial.include?(ns) == !!ns.trial_active?

          expect(consistent).to be true
        end
      end
    end

    describe '.in_default_plan' do
      subject { described_class.in_default_plan.ids }

      where(:plan_name, :expect_in_default_plan) do
        ::Plan::FREE     | true
        ::Plan::DEFAULT  | true
        ::Plan::BRONZE   | false
        ::Plan::SILVER   | false
        ::Plan::PREMIUM  | false
        ::Plan::GOLD     | false
        ::Plan::ULTIMATE | false
      end

      with_them do
        it 'returns expected result' do
          namespace = create(:namespace_with_plan, plan: "#{plan_name}_plan")

          is_expected.to eq(expect_in_default_plan ? [namespace.id] : [])
        end
      end

      it 'includes namespace with no subscription' do
        namespace = create(:namespace)

        is_expected.to eq([namespace.id])
      end
    end

    describe '.eligible_for_trial' do
      let_it_be(:namespace) { create :namespace }

      subject { described_class.eligible_for_trial.first }

      context 'when there is no subscription' do
        it { is_expected.to eq(namespace) }
      end

      context 'when there is a subscription' do
        context 'with a plan that is eligible for a trial' do
          where(plan: ::Plan::PLANS_ELIGIBLE_FOR_TRIAL)

          with_them do
            context 'and has not yet been trialed' do
              before do
                create :gitlab_subscription, plan, namespace: namespace
              end

              it { is_expected.to eq(namespace) }
            end

            context 'but has already had a trial' do
              before do
                create :gitlab_subscription, plan, :expired_trial, namespace: namespace
              end

              it { is_expected.to be_nil }
            end

            context 'but is currently being trialed' do
              before do
                create :gitlab_subscription, plan, :active_trial, namespace: namespace
              end

              it { is_expected.to be_nil }
            end
          end
        end

        context 'with a plan that is ineligible for a trial' do
          where(plan: ::Plan::PAID_HOSTED_PLANS)

          with_them do
            before do
              create :gitlab_subscription, plan, namespace: namespace
            end

            it { is_expected.to be_nil }
          end
        end
      end
    end
  end

  context 'validation' do
    it "ensures max_pages_size is an integer greater than 0 (or equal to 0 to indicate unlimited/maximum)" do
      is_expected.to validate_numericality_of(:max_pages_size).only_integer.is_greater_than_or_equal_to(0)
                       .is_less_than(::Gitlab::Pages::MAX_SIZE / 1.megabyte)
    end
  end

  describe 'custom validations' do
    describe '#validate_shared_runner_minutes_support' do
      context 'when changing :shared_runners_minutes_limit' do
        before do
          group.shared_runners_minutes_limit = 100
        end

        context 'when group is a subgroup' do
          let(:group) { create(:group, :nested) }

          it 'is invalid' do
            expect(group).not_to be_valid
            expect(group.errors[:shared_runners_minutes_limit]).to include('is not supported for this namespace')
          end
        end

        context 'when group is root' do
          let(:group) { create(:group) }

          it 'is valid' do
            expect(group).to be_valid
          end
        end
      end
    end
  end

  describe '#move_dir' do
    context 'when running on a primary node' do
      let_it_be(:primary) { create(:geo_node, :primary) }
      let_it_be(:secondary) { create(:geo_node) }

      let(:gitlab_shell) { Gitlab::Shell.new }
      let(:parent_group) { create(:group) }
      let(:child_group) { create(:group, name: 'child', path: 'child', parent: parent_group) }
      let!(:project_legacy) { create(:project_empty_repo, :legacy_storage, namespace: parent_group) }
      let!(:project_child_hashed) { create(:project, namespace: child_group) }
      let!(:project_child_legacy) { create(:project_empty_repo, :legacy_storage, namespace: child_group) }
      let!(:full_path_before_last_save) { "#{parent_group.full_path}_old" }

      before do
        new_path = parent_group.full_path

        allow(parent_group).to receive(:gitlab_shell).and_return(gitlab_shell)
        allow(parent_group).to receive(:path_changed?).and_return(true)
        allow(parent_group).to receive(:full_path_before_last_save).and_return(full_path_before_last_save)
        allow(parent_group).to receive(:full_path).and_return(new_path)

        allow(gitlab_shell).to receive(:mv_namespace)
          .with(project_legacy.repository_storage, full_path_before_last_save, new_path)
          .and_return(true)

        stub_current_geo_node(primary)
      end

      it 'logs the Geo::RepositoryRenamedEvent for each project inside namespace' do
        expect { parent_group.move_dir }.to change(Geo::RepositoryRenamedEvent, :count).by(3)
      end

      it 'properly builds old_path_with_namespace' do
        parent_group.move_dir

        actual = Geo::RepositoryRenamedEvent.last(3).map(&:old_path_with_namespace)
        expected = %W[
          #{full_path_before_last_save}/#{project_legacy.path}
          #{full_path_before_last_save}/child/#{project_child_hashed.path}
          #{full_path_before_last_save}/child/#{project_child_legacy.path}
        ]

        expect(actual).to match_array(expected)
      end
    end
  end

  shared_examples 'feature available' do
    let(:hosted_plan) { create(:bronze_plan) }
    let(:group) { create(:group) }
    let(:licensed_feature) { :epics }
    let(:feature) { licensed_feature }

    before do
      create(:gitlab_subscription, namespace: group, hosted_plan: hosted_plan)

      stub_licensed_features(licensed_feature => true)
    end

    it 'uses the global setting when running on premise' do
      stub_application_setting_on_object(group, should_check_namespace_plan: false)

      is_expected.to be_truthy
    end

    it 'only checks the plan once' do
      expect(group).to receive(:load_feature_available).once.and_call_original

      2.times { group.licensed_feature_available?(:push_rules) }
    end

    context 'when checking namespace plan' do
      before do
        stub_application_setting_on_object(group, should_check_namespace_plan: true)
      end

      it 'combines the global setting with the group setting when not running on premise' do
        is_expected.to be_falsy
      end

      context 'when feature available on the plan' do
        let(:hosted_plan) { create(:ultimate_plan) }

        context 'when feature available for current group' do
          it 'returns true' do
            is_expected.to be_truthy
          end
        end

        context 'when license is applied to parent group' do
          let(:child_group) { create :group, parent: group }

          it 'child group has feature available' do
            expect(child_group.licensed_feature_available?(feature)).to be_truthy
          end
        end
      end

      context 'when feature not available in the plan' do
        let(:feature) { :cluster_deployments }
        let(:hosted_plan) { create(:bronze_plan) }

        it 'returns false' do
          is_expected.to be_falsy
        end
      end
    end
  end

  describe '#feature_available?' do
    subject { group.licensed_feature_available?(feature) }

    it_behaves_like 'feature available'
  end

  describe '#feature_available_non_trial?' do
    subject { group.feature_available_non_trial?(feature) }

    it_behaves_like 'feature available'

    context 'when the group has an active trial' do
      let(:hosted_plan) { create(:bronze_plan) }
      let(:group) { create(:group) }
      let(:feature) { :resource_access_token }

      before do
        create(:gitlab_subscription, :active_trial, namespace: group, hosted_plan: hosted_plan)
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#actual_limits' do
    subject { namespace.actual_limits }

    shared_examples 'uses an implied configuration' do
      it 'is a non persisted PlanLimits' do
        expect(subject.id).to be_nil
        expect(subject).to be_kind_of(PlanLimits)
      end

      it 'has all limits defined' do
        limits = subject.attributes.except('id', 'plan_id')
        limits.each do |_attribute, limit|
          expect(limit).not_to be_nil
        end
      end
    end

    context 'when no limits are defined in the system' do
      it_behaves_like 'uses an implied configuration'
    end

    context 'when "default" plan is defined in the system' do
      let!(:default_plan) { create(:default_plan) }

      context 'when no limits are set' do
        it_behaves_like 'uses an implied configuration'
      end

      context 'when limits are set for the default plan' do
        let!(:default_limits) do
          create(:plan_limits,
            plan: default_plan,
            ci_active_pipelines: 1,
            ci_pipeline_size: 2,
            ci_active_jobs: 3)
        end

        it { is_expected.to eq(default_limits) }
      end

      context 'when "free" plan is defined in the system' do
        let!(:free_plan) { create(:free_plan) }

        context 'when no limits are set' do
          it_behaves_like 'uses an implied configuration'
        end

        context 'when limits are set for the free plan' do
          let!(:free_limits) do
            create(:plan_limits,
              plan: free_plan,
              ci_active_pipelines: 3,
              ci_pipeline_size: 4,
              ci_active_jobs: 5)
          end

          it { is_expected.to eq(free_limits) }
        end

        context 'when subscription plan is defined in the system' do
          let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan) }

          context 'when limits are not set for the plan' do
            it_behaves_like 'uses an implied configuration'
          end

          context 'when limits are set for the plan' do
            let!(:subscription_limits) do
              create(:plan_limits,
                plan: ultimate_plan,
                ci_active_pipelines: 5,
                ci_pipeline_size: 6,
                ci_active_jobs: 7)
            end

            it { is_expected.to eq(subscription_limits) }
          end
        end
      end
    end
  end

  describe '#any_project_with_shared_runners_enabled?' do
    subject { namespace.any_project_with_shared_runners_enabled? }

    context 'without projects' do
      it { is_expected.to be_falsey }
    end

    context 'group with shared runners enabled project' do
      let!(:project) { create(:project, namespace: namespace, shared_runners_enabled: true) }

      it { is_expected.to be_truthy }
    end

    context 'subgroup with shared runners enabled project' do
      let(:namespace) { create(:group) }
      let(:subgroup) { create(:group, parent: namespace) }
      let!(:subproject) { create(:project, namespace: subgroup, shared_runners_enabled: true) }

      it { is_expected.to be_truthy }
    end

    context 'with project and disabled shared runners' do
      let!(:project) do
        create(:project,
          namespace: namespace,
          shared_runners_enabled: false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#shared_runners_minutes_limit_enabled?' do
    subject { namespace.shared_runners_minutes_limit_enabled? }

    context 'with project' do
      let!(:project) do
        create(:project,
          namespace: namespace,
          shared_runners_enabled: true)
      end

      context 'when no limit defined' do
        it { is_expected.to be_falsey }
      end

      context 'when limit is defined' do
        before do
          namespace.shared_runners_minutes_limit = 500
        end

        it { is_expected.to be_truthy }

        context 'when is subgroup' do
          before do
            namespace.parent = build(:group)
          end

          it { is_expected.to be_falsey }
        end
      end
    end

    context 'without project' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#actual_plan' do
    context 'when namespace does not have a subscription associated' do
      it 'generates a subscription and returns default plan' do
        expect(namespace.actual_plan).to eq(Plan.default)

        # This should be revisited after https://gitlab.com/gitlab-org/gitlab/-/issues/214434
        expect(namespace.gitlab_subscription).to be_present
      end
    end

    context 'when running on Gitlab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      context 'for personal namespaces' do
        context 'when namespace has a subscription associated' do
          before do
            create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan, start_date: start_date)
          end

          context 'when this subscription was purchased before EoA rollout (legacy)' do
            let(:start_date) { GitlabSubscription::EOA_ROLLOUT_DATE.to_date - 3.days }

            it 'returns the legacy plan from the subscription' do
              expect(namespace.actual_plan).to eq(ultimate_plan)
              expect(namespace.gitlab_subscription).to be_present
            end
          end

          context 'when this subscription was purchase after EoA rollout (new plan)' do
            let(:start_date) { GitlabSubscription::EOA_ROLLOUT_DATE.to_date + 3.days }

            it 'returns the new plan from the subscription' do
              expect(namespace.actual_plan).to be_an_instance_of(Subscriptions::NewPlanPresenter)
              expect(namespace.gitlab_subscription).to be_present
            end
          end
        end

        context 'when namespace does not have a subscription associated' do
          it 'generates a subscription and returns free plan' do
            expect(namespace.actual_plan).to eq(Plan.free)
            expect(namespace.gitlab_subscription).to be_present
          end

          context 'when free plan does exist' do
            before do
              free_plan
            end

            it 'generates a subscription' do
              expect(namespace.actual_plan).to eq(free_plan)
              expect(namespace.gitlab_subscription).to be_present
            end
          end
        end
      end

      context 'for groups' do
        context 'when the group is a subgroup with a parent' do
          let(:parent) { create(:group) }
          let(:subgroup) { create(:group, parent: parent) }

          context 'when free plan does exist' do
            before do
              free_plan
            end

            it 'does not generates a subscription' do
              expect(subgroup.actual_plan).to eq(free_plan)
              expect(subgroup.gitlab_subscription).not_to be_present
            end
          end

          context 'when parent group has a subscription associated' do
            before do
              create(:gitlab_subscription, namespace: parent, hosted_plan: ultimate_plan)
            end

            it 'returns the plan from the subscription' do
              expect(subgroup.actual_plan).to eq(ultimate_plan)
              expect(subgroup.gitlab_subscription).not_to be_present
            end
          end
        end
      end
    end
  end

  describe '#paid?' do
    it 'returns true for a root namespace with a paid plan' do
      create(:gitlab_subscription, :ultimate, namespace: namespace)

      expect(namespace.paid?).to eq(true)
    end

    it 'returns false for a subgroup of a group with a paid plan' do
      group = create(:group)
      subgroup = create(:group, parent: group)
      create(:gitlab_subscription, :ultimate, namespace: group)

      expect(subgroup.paid?).to eq(false)
    end
  end

  describe '#actual_plan_name' do
    context 'when namespace does not have a subscription associated' do
      it 'returns default plan' do
        expect(namespace.actual_plan_name).to eq('default')
      end
    end

    context 'when running on Gitlab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      context 'for personal namespaces' do
        context 'when namespace has a subscription associated' do
          before do
            create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan)
          end

          it 'returns an associated plan name' do
            expect(namespace.actual_plan_name).to eq 'ultimate'
          end
        end

        context 'when namespace does not have subscription associated' do
          it 'returns a free plan name' do
            expect(namespace.actual_plan_name).to eq 'free'
          end
        end
      end

      context 'for groups' do
        context 'when the group is a subgroup with a parent' do
          let(:parent) { create(:group) }
          let(:subgroup) { create(:group, parent: parent) }

          context 'when parent group has a subscription associated' do
            before do
              create(:gitlab_subscription, namespace: parent, hosted_plan: ultimate_plan)
            end

            it 'returns an associated plan name' do
              expect(subgroup.actual_plan_name).to eq 'ultimate'
            end
          end

          context 'when parent group does not have subscription associated' do
            it 'returns a free plan name' do
              expect(subgroup.actual_plan_name).to eq 'free'
            end
          end
        end
      end
    end
  end

  shared_context 'project bot users' do
    let(:project_bot) { create(:user, :project_bot) }

    before do
      project.add_maintainer(project_bot)
    end
  end

  describe '#billed_user_ids' do
    context 'with a user namespace' do
      let(:user) { create(:user) }

      it 'returns 1' do
        expect(user.namespace.billed_user_ids.keys).to eq([
          :user_ids,
          :group_member_user_ids,
          :project_member_user_ids,
          :shared_group_user_ids,
          :shared_project_user_ids
        ])
        expect(user.namespace.billed_user_ids[:user_ids]).to eq([user.id])
      end
    end

    context 'with a group namespace' do
      let(:group) { create(:group) }
      let(:developer) { create(:user) }
      let(:guest) { create(:user) }

      before do
        group.add_developer(developer)
        group.add_developer(create(:user, :blocked))
        group.add_guest(guest)
      end

      subject(:billed_user_ids) { group.billed_user_ids }

      it 'returns a breakdown of billable user ids' do
        expect(billed_user_ids.keys).to eq([
          :user_ids,
          :group_member_user_ids,
          :project_member_user_ids,
          :shared_group_user_ids,
          :shared_project_user_ids
        ])
      end

      context 'with a ultimate plan' do
        before do
          create(:gitlab_subscription, namespace: group, hosted_plan: ultimate_plan)
        end

        it 'does not include guest users and only active users' do
          expect(billed_user_ids[:user_ids]).to match_array([developer.id])
        end

        context 'when group has a project and users are invited to it' do
          let(:project) { create(:project, namespace: group) }
          let(:project_developer) { create(:user) }

          before do
            project.add_developer(project_developer)
            project.add_guest(create(:user))
            project.add_developer(developer)
            project.add_developer(create(:user, :blocked))
          end

          it 'includes invited active users except guests to the group', :aggregate_failures do
            expect(billed_user_ids[:user_ids]).to match_array([project_developer.id, developer.id])
            expect(billed_user_ids[:project_member_user_ids]).to match_array([project_developer.id, developer.id])
            expect(billed_user_ids[:group_member_user_ids]).to match_array([developer.id])
            expect(billed_user_ids[:shared_group_user_ids]).to match_array([])
            expect(billed_user_ids[:shared_project_user_ids]).to match_array([])
          end

          context 'with project bot users' do
            include_context 'project bot users'

            it { expect(billed_user_ids[:user_ids]).not_to include(project_bot.id) }
            it { expect(billed_user_ids[:project_member_user_ids]).not_to include(project_bot.id) }
          end

          context 'when group is invited to the project' do
            let(:invited_group) { create(:group) }
            let(:invited_group_developer) { create(:user) }

            before do
              invited_group.add_developer(invited_group_developer)
              invited_group.add_guest(create(:user))
              invited_group.add_developer(create(:user, :blocked))
              invited_group.add_developer(developer)
            end

            context 'when group is invited as non guest' do
              before do
                create(:project_group_link, project: project, group: invited_group)
              end

              it 'includes only active users except guests of the invited groups', :aggregate_failures do
                expect(billed_user_ids[:user_ids]).to match_array([invited_group_developer.id, project_developer.id, developer.id])
                expect(billed_user_ids[:shared_group_user_ids]).to match_array([])
                expect(billed_user_ids[:shared_project_user_ids]).to match_array([invited_group_developer.id, developer.id])
                expect(billed_user_ids[:group_member_user_ids]).to match_array([developer.id])
                expect(billed_user_ids[:project_member_user_ids]).to match_array([developer.id, project_developer.id])
              end
            end

            context 'when group is invited as a guest to the project' do
              before do
                create(:project_group_link, :guest, project: project, group: invited_group)
              end

              it 'does not include any members from the invited group', :aggregate_failures do
                expect(billed_user_ids[:user_ids]).to match_array([project_developer.id, developer.id])
                expect(billed_user_ids[:shared_project_user_ids]).to be_empty
              end
            end
          end
        end

        context 'when group has been shared with another group' do
          let(:shared_group) { create(:group) }
          let(:shared_group_developer) { create(:user) }

          before do
            shared_group.add_developer(shared_group_developer)
            shared_group.add_guest(create(:user))
            shared_group.add_developer(create(:user, :blocked))

            create(:group_group_link, { shared_with_group: shared_group,
                                        shared_group: group })
          end

          it 'includes active users from the shared group to the billed members', :aggregate_failures do
            expect(billed_user_ids[:user_ids]).to match_array([shared_group_developer.id, developer.id])
            expect(billed_user_ids[:shared_group_user_ids]).to match_array([shared_group_developer.id])
            expect(shared_group.billed_user_ids[:user_ids]).not_to include([developer.id])
          end

          context 'when subgroup invited another group to collaborate' do
            let(:another_shared_group) { create(:group) }
            let(:another_shared_group_developer) { create(:user) }

            before do
              another_shared_group.add_developer(another_shared_group_developer)
              another_shared_group.add_guest(create(:user))
              another_shared_group.add_developer(create(:user, :blocked))
            end

            context 'when subgroup invites another group as non guest' do
              before do
                subgroup = create(:group, parent: group)
                create(:group_group_link, { shared_with_group: another_shared_group,
                                            shared_group: subgroup })
              end

              it 'includes all the active and non guest users from the shared group', :aggregate_failures do
                expect(billed_user_ids[:user_ids]).to match_array([shared_group_developer.id, developer.id, another_shared_group_developer.id])
                expect(billed_user_ids[:shared_group_user_ids]).to match_array([shared_group_developer.id, another_shared_group_developer.id])
                expect(shared_group.billed_user_ids[:user_ids]).not_to include([developer.id])
                expect(another_shared_group.billed_user_ids[:user_ids]).not_to include([developer.id, shared_group_developer.id])
              end
            end

            context 'when subgroup invites another group as guest' do
              before do
                subgroup = create(:group, parent: group)
                create(:group_group_link, :guest, { shared_with_group: another_shared_group,
                                                    shared_group: subgroup })
              end

              it 'does not includes any user from the shared group from the subgroup', :aggregate_failures do
                expect(billed_user_ids[:user_ids]).to match_array([shared_group_developer.id, developer.id])
                expect(billed_user_ids[:shared_group_user_ids]).to match_array([shared_group_developer.id])
              end
            end
          end
        end
      end

      context 'with other plans' do
        %i[bronze_plan premium_plan].each do |plan|
          subject(:billed_user_ids) { group.billed_user_ids }

          it 'includes active guest users', :aggregate_failures do
            create(:gitlab_subscription, namespace: group, hosted_plan: send(plan))
            expect(billed_user_ids[:user_ids]).to match_array([guest.id, developer.id])
            expect(billed_user_ids[:group_member_user_ids]).to match_array([guest.id, developer.id])
          end

          context 'when group has a project and users invited to it' do
            let(:project) { create(:project, namespace: group) }
            let(:project_developer) { create(:user) }
            let(:project_guest) { create(:user) }

            before do
              create(:gitlab_subscription, namespace: group, hosted_plan: send(plan))
              project.add_developer(project_developer)
              project.add_guest(project_guest)
              project.add_developer(create(:user, :blocked))
              project.add_developer(developer)
            end

            it 'includes invited active users to the group', :aggregate_failures do
              expect(billed_user_ids[:user_ids]).to match_array([guest.id, developer.id, project_guest.id, project_developer.id])
              expect(billed_user_ids[:project_member_user_ids]).to match_array([developer.id, project_guest.id, project_developer.id])
            end

            context 'with project bot users' do
              include_context 'project bot users'

              it { expect(billed_user_ids[:user_ids]).not_to include(project_bot.id) }
              it { expect(billed_user_ids[:project_member_user_ids]).not_to include(project_bot.id) }
            end

            context 'when group is invited to the project' do
              let(:invited_group) { create(:group) }
              let(:invited_group_developer) { create(:user) }
              let(:invited_group_guest) { create(:user) }

              before do
                invited_group.add_developer(invited_group_developer)
                invited_group.add_developer(developer)
                invited_group.add_guest(invited_group_guest)
                invited_group.add_developer(create(:user, :blocked))
                create(:project_group_link, project: project, group: invited_group)
              end

              it 'includes the unique active users and guests of the invited groups', :aggregate_failures do
                expect(billed_user_ids[:user_ids]).to match_array([
                  guest.id,
                  developer.id,
                  project_guest.id,
                  project_developer.id,
                  invited_group_developer.id,
                  invited_group_guest.id
                ])

                expect(billed_user_ids[:shared_project_user_ids]).to match_array([
                  developer.id,
                  invited_group_developer.id,
                  invited_group_guest.id
                ])
              end
            end
          end

          context 'when group has been shared with another group' do
            let(:shared_group) { create(:group) }
            let(:shared_group_developer) { create(:user) }
            let(:shared_group_guest) { create(:user) }

            before do
              create(:gitlab_subscription, namespace: group, hosted_plan: send(plan))
              shared_group.add_developer(shared_group_developer)
              shared_group.add_guest(shared_group_guest)
              shared_group.add_developer(create(:user, :blocked))

              create(:group_group_link, { shared_with_group: shared_group,
                                          shared_group: group })
            end

            it 'includes active users from the shared group including guests', :aggregate_failures do
              expect(billed_user_ids[:user_ids]).to match_array([developer.id, guest.id, shared_group_developer.id, shared_group_guest.id])
              expect(billed_user_ids[:shared_group_user_ids]).to match_array([shared_group_developer.id, shared_group_guest.id])
              expect(shared_group.billed_user_ids[:user_ids]).to match_array([shared_group_developer.id, shared_group_guest.id])
            end
          end
        end
      end
    end
  end

  describe '#billable_members_count' do
    context 'with a user namespace' do
      let(:user) { create(:user) }

      it 'returns 1' do
        expect(user.namespace.billable_members_count).to eq(1)
      end
    end

    context 'with a group namespace' do
      let(:group) { create(:group) }
      let(:developer) { create(:user) }

      before do
        group.add_developer(developer)
        group.add_developer(create(:user, :blocked))
        group.add_guest(create(:user))
      end

      context 'with a ultimate plan' do
        before do
          create(:gitlab_subscription, namespace: group, hosted_plan: ultimate_plan)
        end

        it 'does not count guest users and counts only active users' do
          expect(group.billable_members_count).to eq(1)
        end

        context 'when group has a project and users invited to it' do
          let(:project) { create(:project, namespace: group) }

          before do
            project.add_developer(create(:user))
            project.add_guest(create(:user))
            project.add_developer(developer)
            project.add_developer(create(:user, :blocked))
          end

          it 'includes invited active users except guests to the group' do
            expect(group.billable_members_count).to eq(2)
          end

          context 'with project bot users' do
            include_context 'project bot users'

            it { expect(group.billable_members_count).to eq(2) }
          end

          context 'when group is invited to the project' do
            let(:invited_group) { create(:group) }

            before do
              invited_group.add_developer(create(:user))
              invited_group.add_guest(create(:user))
              invited_group.add_developer(create(:user, :blocked))
              invited_group.add_developer(developer)
              create(:project_group_link, project: project, group: invited_group)
            end

            it 'counts the only active users except guests of the invited groups' do
              expect(group.billable_members_count).to eq(3)
            end
          end
        end

        context 'when group has been shared with another group' do
          let(:shared_group) { create(:group) }

          before do
            shared_group.add_developer(create(:user))
            shared_group.add_guest(create(:user))
            shared_group.add_developer(create(:user, :blocked))

            create(:group_group_link, { shared_with_group: shared_group,
                                        shared_group: group })
          end

          it 'includes active users from the shared group to the billed members count' do
            expect(group.billable_members_count).to eq(2)
          end
        end
      end

      context 'with other plans' do
        %i[bronze_plan premium_plan].each do |plan|
          it 'counts active guest users' do
            create(:gitlab_subscription, namespace: group, hosted_plan: send(plan))
            expect(group.billable_members_count).to eq(2)
          end

          context 'when group has a project and users invited to it' do
            let(:project) { create(:project, namespace: group) }

            before do
              create(:gitlab_subscription, namespace: group, hosted_plan: send(plan))
              project.add_developer(create(:user))
              project.add_guest(create(:user))
              project.add_developer(create(:user, :blocked))
              project.add_developer(developer)
            end

            it 'includes invited active users to the group' do
              expect(group.billable_members_count).to eq(4)
            end

            context 'with project bot users' do
              include_context 'project bot users'

              it { expect(group.billable_members_count).to eq(4) }
            end

            context 'when group is invited to the project' do
              let(:invited_group) { create(:group) }

              before do
                invited_group.add_developer(create(:user))
                invited_group.add_developer(developer)
                invited_group.add_guest(create(:user))
                invited_group.add_developer(create(:user, :blocked))
                create(:project_group_link, project: project, group: invited_group)
              end

              it 'counts the unique active users including guests of the invited groups' do
                expect(group.billable_members_count).to eq(6)
              end
            end
          end

          context 'when group has been shared with another group' do
            let(:shared_group) { create(:group) }

            before do
              create(:gitlab_subscription, namespace: group, hosted_plan: send(plan))
              shared_group.add_developer(create(:user))
              shared_group.add_guest(create(:user))
              shared_group.add_developer(create(:user, :blocked))

              create(:group_group_link, { shared_with_group: shared_group,
                                          shared_group: group })
            end

            it 'includes active users from the shared group including guests to the billed members count' do
              expect(group.billable_members_count).to eq(4)
            end
          end
        end
      end
    end
  end

  describe '#eligible_for_trial?' do
    subject { namespace.eligible_for_trial? }

    where(
      on_dot_com: [true, false],
      has_parent: [true, false],
      never_had_trial: [true, false],
      plan_eligible_for_trial: [true, false]
    )

    with_them do
      before do
        allow(Gitlab).to receive(:com?).and_return(on_dot_com)
        allow(namespace).to receive(:has_parent?).and_return(has_parent)
        allow(namespace).to receive(:never_had_trial?).and_return(never_had_trial)
        allow(namespace).to receive(:plan_eligible_for_trial?).and_return(plan_eligible_for_trial)
      end

      context "when#{' not' unless params[:on_dot_com]} on .com" do
        context "and the namespace #{params[:has_parent] ? 'has' : 'is'} a parent namespace" do
          context "and the namespace has#{' not yet' if params[:never_had_trial]} been trialed" do
            context "and the namespace is#{' not' unless params[:plan_eligible_for_trial]} eligible for a trial" do
              it { is_expected.to eq(on_dot_com && !has_parent && never_had_trial && plan_eligible_for_trial) }
            end
          end
        end
      end
    end
  end

  describe '#can_extend_trial?' do
    subject { namespace.can_extend_trial? }

    context 'feature flag is disabled' do
      before do
        allow(namespace).to receive(:trial_active?).and_return(true)
        allow(namespace).to receive(:trial_extended_or_reactivated?).and_return(false)

        stub_feature_flags(allow_extend_reactivate_trial: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when feature flag is enabled' do
      where(:trial_active, :trial_extended_or_reactivated, :can_extend_trial) do
        false | false | false
        false | true  | false
        true  | false | true
        true  | true  | false
      end

      with_them do
        before do
          allow(namespace).to receive(:trial_active?).and_return(trial_active)
          allow(namespace).to receive(:trial_extended_or_reactivated?).and_return(trial_extended_or_reactivated)
        end

        it { is_expected.to be can_extend_trial }
      end
    end
  end

  describe '#can_reactivate_trial?' do
    subject { namespace.can_reactivate_trial? }

    context 'when feature flag is disabled' do
      before do
        allow(namespace).to receive(:trial_active?).and_return(false)
        allow(namespace).to receive(:never_had_trial?).and_return(false)
        allow(namespace).to receive(:trial_extended_or_reactivated?).and_return(false)
        allow(namespace).to receive(:free_plan?).and_return(true)

        stub_feature_flags(allow_extend_reactivate_trial: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when feature flag is enabled' do
      where(:trial_active, :never_had_trial, :trial_extended_or_reactivated, :free_plan, :can_reactivate_trial) do
        false | false | false | false | false
        false | false | false | true  | true
        false | false | true  | false | false
        false | false | true  | true  | false
        false | true  | false | false | false
        false | true  | false | true  | false
        false | true  | true  | false | false
        false | true  | true  | true  | false
        true  | false | false | false | false
        true  | false | false | true  | false
        true  | false | true  | false | false
        true  | false | true  | true  | false
        true  | true  | false | false | false
        true  | true  | false | true  | false
        true  | true  | true  | false | false
        true  | true  | true  | true  | false
      end

      with_them do
        before do
          allow(namespace).to receive(:trial_active?).and_return(trial_active)
          allow(namespace).to receive(:never_had_trial?).and_return(never_had_trial)
          allow(namespace).to receive(:trial_extended_or_reactivated?).and_return(trial_extended_or_reactivated)
          allow(namespace).to receive(:free_plan?).and_return(free_plan)
        end

        it { is_expected.to be can_reactivate_trial }
      end
    end
  end

  describe '#file_template_project_id' do
    it 'is cleared before validation' do
      project = create(:project, namespace: namespace)

      namespace.file_template_project_id = project.id

      expect(namespace).to be_valid
      expect(namespace.file_template_project_id).to be_nil
    end
  end

  describe '#checked_file_template_project' do
    it 'is always nil' do
      namespace.file_template_project_id = create(:project, namespace: namespace).id

      expect(namespace.checked_file_template_project).to be_nil
    end
  end

  describe '#checked_file_template_project_id' do
    it 'is always nil' do
      namespace.file_template_project_id = create(:project, namespace: namespace).id

      expect(namespace.checked_file_template_project_id).to be_nil
    end
  end

  describe '#store_security_reports_available?' do
    subject { namespace.store_security_reports_available? }

    context 'when at least one security report feature is enabled' do
      where(report_type: [:sast, :secret_detection, :dast, :dependency_scanning, :container_scanning, :cluster_image_scanning])

      with_them do
        before do
          stub_licensed_features(report_type => true)
        end

        it { is_expected.to be true }
      end
    end

    context 'when no security report feature is available' do
      before do
        stub_feature_flags(store_security_reports: true)
      end

      it { is_expected.to be false }
    end
  end

  describe '#over_storage_limit?' do
    using RSpec::Parameterized::TableSyntax

    where(:enforcement_setting_enabled, :feature_enabled, :above_size_limit, :result) do
      false | false | false | false
      false | false | true  | false
      false | true  | false | false
      false | true  | true  | false
      true  | false | false | false
      true  | false | true  | false
      true  | true  | false | false
      true  | true  | true  | true
    end

    with_them do
      before do
        stub_application_setting(enforce_namespace_storage_limit: enforcement_setting_enabled)
        stub_feature_flags(namespace_storage_limit: feature_enabled)
        allow_next_instance_of(EE::Namespace::RootStorageSize, namespace.root_ancestor) do |project|
          allow(project).to receive(:above_size_limit?).and_return(above_size_limit)
        end
      end

      it 'returns a boolean indicating whether the root namespace is over the storage limit' do
        expect(namespace.over_storage_limit?).to be result
      end
    end
  end

  describe '#total_repository_size_excess' do
    let_it_be(:namespace) { create(:namespace) }

    before do
      namespace.clear_memoization(:total_repository_size_excess)
    end

    context 'projects with a variety of repository sizes and limits' do
      before_all do
        create_storage_excess_example_projects
      end

      context 'when namespace-level repository_size_limit is not set' do
        it 'returns the total excess size of projects with repositories that exceed the size limit' do
          allow(namespace).to receive(:actual_size_limit).and_return(nil)

          expect(namespace.total_repository_size_excess).to eq(400)
        end
      end

      context 'when namespace-level repository_size_limit is 0 (unlimited)' do
        it 'returns the total excess size of projects with repositories that exceed the size limit' do
          allow(namespace).to receive(:actual_size_limit).and_return(0)

          expect(namespace.total_repository_size_excess).to eq(400)
        end
      end

      context 'when namespace-level repository_size_limit is a positive number' do
        it 'returns the total excess size of projects with repositories that exceed the size limit' do
          allow(namespace).to receive(:actual_size_limit).and_return(150)

          expect(namespace.total_repository_size_excess).to eq(560)
        end
      end
    end

    context 'when all projects have repository_size_limit of 0 (unlimited)' do
      before do
        create_project(repository_size: 100, lfs_objects_size: 0, repository_size_limit: 0)
        create_project(repository_size: 150, lfs_objects_size: 0, repository_size_limit: 0)
        create_project(repository_size: 200, lfs_objects_size: 100, repository_size_limit: 0)

        allow(namespace).to receive(:actual_size_limit).and_return(150)
      end

      it 'returns zero regardless of the namespace or instance-level repository_size_limit' do
        expect(namespace.total_repository_size_excess).to eq(0)
      end
    end
  end

  describe '#repository_size_excess_project_count' do
    let_it_be(:namespace) { create(:namespace) }

    before do
      namespace.clear_memoization(:repository_size_excess_project_count)
    end

    context 'projects with a variety of repository sizes and limits' do
      before_all do
        create_storage_excess_example_projects
      end

      context 'when namespace-level repository_size_limit is not set' do
        before do
          allow(namespace).to receive(:actual_size_limit).and_return(nil)
        end

        it 'returns the count of projects with repositories that exceed the size limit' do
          expect(namespace.repository_size_excess_project_count).to eq(2)
        end
      end

      context 'when namespace-level repository_size_limit is 0 (unlimited)' do
        before do
          allow(namespace).to receive(:actual_size_limit).and_return(0)
        end

        it 'returns the count of projects with repositories that exceed the size limit' do
          expect(namespace.repository_size_excess_project_count).to eq(2)
        end
      end

      context 'when namespace-level repository_size_limit is a positive number' do
        before do
          allow(namespace).to receive(:actual_size_limit).and_return(150)
        end

        it 'returns the count of projects with repositories that exceed the size limit' do
          expect(namespace.repository_size_excess_project_count).to eq(4)
        end
      end
    end

    context 'when all projects have repository_size_limit of 0 (unlimited)' do
      before do
        create_project(repository_size: 100, lfs_objects_size: 0, repository_size_limit: 0)
        create_project(repository_size: 150, lfs_objects_size: 0, repository_size_limit: 0)
        create_project(repository_size: 200, lfs_objects_size: 100, repository_size_limit: 0)

        allow(namespace).to receive(:actual_size_limit).and_return(150)
      end

      it 'returns zero regardless of the namespace or instance-level repository_size_limit' do
        expect(namespace.repository_size_excess_project_count).to eq(0)
      end
    end
  end

  describe '#total_repository_size' do
    let(:namespace) { create(:namespace) }

    before do
      create_project(repository_size: 100, lfs_objects_size: 0, repository_size_limit: nil)
      create_project(repository_size: 150, lfs_objects_size: 100, repository_size_limit: 0)
      create_project(repository_size: 325, lfs_objects_size: 200, repository_size_limit: 400)
    end

    it 'returns the total size of all project repositories' do
      expect(namespace.total_repository_size).to eq(875)
    end
  end

  describe '#contains_locked_projects?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:namespace) { create(:namespace) }

    before_all do
      create(:namespace_limit, namespace: namespace, additional_purchased_storage_size: 10)
    end

    where(:total_excess, :result) do
      5.megabytes  | false
      10.megabytes | false
      15.megabytes | true
    end

    with_them do
      before do
        allow(namespace).to receive(:total_repository_size_excess).and_return(total_excess)
      end

      it 'returns a boolean indicating whether the root namespace contains locked projects' do
        expect(namespace.contains_locked_projects?).to be result
      end
    end
  end

  describe '#actual_size_limit' do
    let(:namespace) { build(:namespace) }

    before do
      allow_any_instance_of(ApplicationSetting).to receive(:repository_size_limit).and_return(50)
    end

    it 'returns the correct size limit' do
      expect(namespace.actual_size_limit).to eq(50)
    end
  end

  describe '#membership_lock with subgroups' do
    context 'when creating a subgroup' do
      let(:subgroup) { create(:group, parent: root_group) }

      context 'under a parent with "Membership lock" enabled' do
        let(:root_group) { create(:group, membership_lock: true) }

        it 'enables "Membership lock" on the subgroup' do
          expect(subgroup.membership_lock).to be_truthy
        end
      end

      context 'under a parent with "Membership lock" disabled' do
        let(:root_group) { create(:group) }

        it 'does not enable "Membership lock" on the subgroup' do
          expect(subgroup.membership_lock).to be_falsey
        end
      end

      context 'when enabling the parent group "Membership lock"' do
        let(:root_group) { create(:group) }
        let!(:subgroup) { create(:group, parent: root_group) }

        it 'the subgroup "Membership lock" not changed' do
          root_group.update!(membership_lock: true)

          expect(subgroup.reload.membership_lock).to be_falsey
        end
      end

      context 'when disabling the parent group "Membership lock" (which was already enabled)' do
        let(:root_group) { create(:group, membership_lock: true) }

        context 'and the subgroup "Membership lock" is enabled' do
          let(:subgroup) { create(:group, parent: root_group, membership_lock: true) }

          it 'the subgroup "Membership lock" does not change' do
            root_group.update!(membership_lock: false)

            expect(subgroup.reload.membership_lock).to be_truthy
          end
        end

        context 'but the subgroup "Membership lock" is disabled' do
          let(:subgroup) { create(:group, parent: root_group) }

          it 'the subgroup "Membership lock" does not change' do
            root_group.update!(membership_lock: false)

            expect(subgroup.reload.membership_lock?).to be_falsey
          end
        end
      end
    end

    # Note: Group transfers are not yet implemented
    context 'when a group is transferred into a root group' do
      context 'when the root group "Membership lock" is enabled' do
        let(:root_group) { create(:group, membership_lock: true) }

        context 'when the subgroup "Membership lock" is enabled' do
          let(:subgroup) { create(:group, membership_lock: true) }

          it 'the subgroup "Membership lock" does not change' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.membership_lock).to be_truthy
          end
        end

        context 'when the subgroup "Membership lock" is disabled' do
          let(:subgroup) { create(:group) }

          it 'the subgroup "Membership lock" not changed' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.membership_lock).to be_falsey
          end
        end
      end

      context 'when the root group "Membership lock" is disabled' do
        let(:root_group) { create(:group) }

        context 'when the subgroup "Membership lock" is enabled' do
          let(:subgroup) { create(:group, membership_lock: true) }

          it 'the subgroup "Membership lock" does not change' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.membership_lock).to be_truthy
          end
        end

        context 'when the subgroup "Membership lock" is disabled' do
          let(:subgroup) { create(:group) }

          it 'the subgroup "Membership lock" does not change' do
            subgroup.parent = root_group
            subgroup.save!

            expect(subgroup.membership_lock).to be_falsey
          end
        end
      end
    end
  end

  describe '#closest_gitlab_subscription' do
    subject { group.closest_gitlab_subscription }

    context 'when there is a root ancestor' do
      let(:group) { create(:group, parent: root) }

      context 'when root has a subscription' do
        let(:root) { create(:group_with_plan) }

        it { is_expected.to be_a(GitlabSubscription) }
      end

      context 'when root has no subscription' do
        let(:root) { create(:group) }

        it { is_expected.to be_nil }
      end
    end

    context 'when there is no root ancestor' do
      context 'for groups' do
        context 'has a subscription' do
          let(:group) { create(:group_with_plan) }

          it { is_expected.to be_a(GitlabSubscription) }
        end

        context 'it has no subscription' do
          let(:group) { create(:group) }

          it { is_expected.to be_nil }
        end
      end

      context 'for personal namespaces' do
        subject { namespace.closest_gitlab_subscription }

        context 'has a subscription' do
          let(:namespace) { create(:namespace_with_plan) }

          it { is_expected.to be_a(GitlabSubscription) }
        end

        context 'it has no subscription' do
          let(:namespace) { create(:namespace) }

          it { is_expected.to be_nil }
        end
      end
    end
  end

  describe '#namespace_limit' do
    let(:group) { create(:group, parent: parent) }

    subject(:namespace_limit) { group.namespace_limit }

    context 'when there is a parent namespace' do
      let_it_be(:parent) { create(:group) }

      context 'with a namespace limit' do
        it 'returns the parent namespace limit' do
          parent_limit = create(:namespace_limit, namespace: parent)

          expect(namespace_limit).to eq parent_limit
          expect(namespace_limit).to be_persisted
        end
      end

      context 'with no namespace limit' do
        it 'builds namespace limit' do
          expect(namespace_limit).to be_present
          expect(namespace_limit).not_to be_persisted
        end
      end
    end

    context 'when there is no parent ancestor' do
      let(:parent) { nil }

      context 'for personal namespaces' do
        let(:namespace) { create(:namespace, parent: parent) }

        subject(:namespace_limit) { namespace.namespace_limit }

        context 'with a namespace limit' do
          it 'returns the namespace limit' do
            limit = create(:namespace_limit, namespace: namespace)

            expect(namespace_limit).to be_persisted
            expect(namespace_limit).to eq limit
          end
        end

        context 'with no namespace limit' do
          it 'builds namespace limit' do
            expect(namespace_limit).to be_present
            expect(namespace_limit).not_to be_persisted
          end
        end
      end

      context 'for groups' do
        context 'with a namespace limit' do
          it 'returns the namespace limit' do
            limit = create(:namespace_limit, namespace: group)

            expect(namespace_limit).to be_persisted
            expect(namespace_limit).to eq limit
          end
        end

        context 'with no namespace limit' do
          it 'builds namespace limit' do
            expect(namespace_limit).to be_present
            expect(namespace_limit).not_to be_persisted
          end
        end
      end
    end
  end

  describe '#enable_temporary_storage_increase!' do
    it 'sets a date' do
      namespace = build(:namespace)

      freeze_time do
        namespace.enable_temporary_storage_increase!

        expect(namespace.temporary_storage_increase_ends_on).to eq(30.days.from_now.to_date)
      end
    end

    it 'is invalid when set twice' do
      namespace = create(:namespace)

      namespace.enable_temporary_storage_increase!
      namespace.enable_temporary_storage_increase!

      expect(namespace).to be_invalid
      expect(namespace.errors[:"namespace_limit.temporary_storage_increase_ends_on"]).to be_present
    end
  end

  describe '#additional_repo_storage_by_namespace_enabled?' do
    let_it_be(:namespace) { build(:namespace) }

    subject { namespace.additional_repo_storage_by_namespace_enabled? }

    where(:namespace_storage_limit, :automatic_purchased_storage_allocation, :result) do
      false | false | false
      false | true  | true
      true  | false | false
      true  | true  | false
    end

    with_them do
      before do
        stub_feature_flags(namespace_storage_limit: namespace_storage_limit)
        stub_application_setting(automatic_purchased_storage_allocation: automatic_purchased_storage_allocation)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#root_storage_size' do
    let_it_be(:namespace) { build(:namespace) }

    subject { namespace.root_storage_size }

    before do
      allow(namespace).to receive(:additional_repo_storage_by_namespace_enabled?)
        .and_return(additional_repo_storage_by_namespace_enabled)
    end

    context 'when additional_repo_storage_by_namespace_enabled is false' do
      let(:additional_repo_storage_by_namespace_enabled) { false }

      it 'initializes a new instance of EE::Namespace::RootStorageSize' do
        expect(EE::Namespace::RootStorageSize).to receive(:new).with(namespace)

        subject
      end
    end

    context 'when additional_repo_storage_by_namespace_enabled is true' do
      let(:additional_repo_storage_by_namespace_enabled) { true }

      it 'initializes a new instance of EE::Namespace::RootExcessStorageSize' do
        expect(EE::Namespace::RootExcessStorageSize).to receive(:new).with(namespace)

        subject
      end
    end
  end

  def create_project(repository_size:, lfs_objects_size:, repository_size_limit:)
    create(:project, namespace: namespace, repository_size_limit: repository_size_limit).tap do |project|
      create(:project_statistics, project: project, repository_size: repository_size, lfs_objects_size: lfs_objects_size)
    end
  end

  def create_storage_excess_example_projects
    [
      { repository_size: 100, lfs_objects_size: 0, repository_size_limit: nil },
      { repository_size: 150, lfs_objects_size: 0, repository_size_limit: nil },
      { repository_size: 140, lfs_objects_size: 10, repository_size_limit: nil },
      { repository_size: 150, lfs_objects_size: 10, repository_size_limit: nil },
      { repository_size: 200, lfs_objects_size: 100, repository_size_limit: nil },
      { repository_size: 100, lfs_objects_size: 0, repository_size_limit: 0 },
      { repository_size: 150, lfs_objects_size: 10, repository_size_limit: 0 },
      { repository_size: 200, lfs_objects_size: 100, repository_size_limit: 0 },
      { repository_size: 300, lfs_objects_size: 0, repository_size_limit: 400 },
      { repository_size: 400, lfs_objects_size: 0, repository_size_limit: 400 },
      { repository_size: 300, lfs_objects_size: 100, repository_size_limit: 400 },
      { repository_size: 400, lfs_objects_size: 100, repository_size_limit: 400 },
      { repository_size: 500, lfs_objects_size: 100, repository_size_limit: 300 }
    ].map { |attrs| create_project(**attrs) }
  end
end
