# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace do
  using RSpec::Parameterized::TableSyntax

  include EE::GeoHelpers
  include NamespaceStorageHelpers

  let(:namespace) { create(:namespace) }
  let!(:ultimate_plan) { create(:ultimate_plan) }

  it { is_expected.to have_one(:namespace_limit) }
  it { is_expected.to have_one(:elasticsearch_indexed_namespace) }
  it { is_expected.to have_one(:security_orchestration_policy_configuration).class_name('Security::OrchestrationPolicyConfiguration').with_foreign_key(:namespace_id) }
  it { is_expected.to have_one :upcoming_reconciliation }
  it { is_expected.to have_one(:storage_limit_exclusion) }
  it { is_expected.to have_many(:ci_minutes_additional_packs) }
  it { is_expected.to have_many(:member_roles) }

  it { is_expected.to delegate_method(:trial?).to(:gitlab_subscription) }
  it { is_expected.to delegate_method(:trial_ends_on).to(:gitlab_subscription) }
  it { is_expected.to delegate_method(:trial_starts_on).to(:gitlab_subscription) }
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
      where(plan_name: ::Plan.all_plans - [namespace_plan])

      with_them do
        it { is_expected.to eq(false) }
      end
    end
  end

  ::Plan.all_plans.each do |namespace_plan|
    describe "#{namespace_plan}_plan?", :saas do
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
        allow(namespace).to receive(:user_namespace?).and_return(user)
        allow(namespace).to receive(:paid?).and_return(paid)
      end

      it 'returns expected boolean value' do
        expect(namespace.free_personal?).to eq(expected)
      end
    end
  end

  describe '#prevent_delete?' do
    where(:paid, :trial, :expected) do
      true  | false | true
      false | false | false
      false | true  | false
      true  | true  | false
    end

    with_them do
      before do
        allow(namespace).to receive(:trial?).and_return(trial)
        allow(namespace).to receive(:paid?).and_return(paid)
      end

      it 'returns expected boolean value' do
        expect(namespace.prevent_delete?).to eq(expected)
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

  describe '#use_zoekt?', feature_category: :global_search do
    it 'delegates to ::Zoekt::IndexedNamespace' do
      expect(::Zoekt::IndexedNamespace).to receive(:enabled_for_namespace?).with(namespace).and_return(true)

      expect(namespace.use_zoekt?).to eq(true)
    end
  end

  describe '#has_index_assignment?', feature_category: :global_search do
    it 'delegates to ::Search::NamespaceIndexAssignment' do
      index_type = Search::NoteIndex
      expect(::Search::NamespaceIndexAssignment).to receive(:has_assignment?)
        .with(namespace: namespace, type: index_type).and_return(true)
      expect(namespace.has_index_assignment?(type: index_type)).to eq(true)
    end
  end

  describe '#hashed_root_namespace_id', feature_category: :global_search do
    it 'delegates to Search.hash_namespace_id' do
      expect(::Search).to receive(:hash_namespace_id).with(namespace.root_ancestor.id).and_return 8_675_309
      expect(namespace.hashed_root_namespace_id).to eq(8_675_309)
    end
  end

  describe '#invalidate_elasticsearch_indexes_cache!' do
    let(:namespace) { create :namespace }

    it 'clears the cache for the namespace' do
      expect(::Gitlab::Elastic::ElasticsearchEnabledCache).to receive(:delete_record).with(:namespace, namespace.id)

      namespace.invalidate_elasticsearch_indexes_cache!
    end
  end

  describe '#actual_plan_name' do
    let_it_be(:namespace, refind: true) { create(:namespace) }

    subject(:actual_plan_name) { namespace.actual_plan_name }

    context 'when namespace does not have a subscription associated' do
      it 'returns default plan' do
        expect(actual_plan_name).to eq('default')
      end
    end

    context 'when running on Gitlab.com', :saas do
      context 'when namespace has a subscription associated' do
        before do
          create(:gitlab_subscription, namespace: namespace, hosted_plan: ultimate_plan)
        end

        it 'returns the associated plan name' do
          expect(actual_plan_name).to eq 'ultimate'
        end
      end

      context 'when namespace does not have subscription associated' do
        it 'returns a free plan name' do
          expect(actual_plan_name).to eq 'free'
        end
      end

      context 'when the database is read-only' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
        end

        it 'returns free plan' do
          expect(Gitlab::Database).to receive(:read_only?)

          expect(actual_plan_name).to eq('free')
        end

        it 'does not create a gitlab_subscription' do
          expect(Gitlab::Database).to receive(:read_only?)

          expect { actual_plan_name }.not_to change { GitlabSubscription.count }
        end
      end

      context 'when namespace is not persisted' do
        let(:namespace) { build(:namespace) }

        it 'returns free plan' do
          expect(actual_plan_name).to eq('free')
        end

        it 'does not create a gitlab_subscription' do
          expect { actual_plan_name }.not_to change { GitlabSubscription.count }
        end
      end

      context 'when the database is not read-only' do
        it 'returns free plan' do
          expect(actual_plan_name).to eq('free')
        end

        it 'creates a gitlab_subscription' do
          expect { actual_plan_name }.to change { GitlabSubscription.count }.by(1)
        end
      end
    end
  end

  context 'scopes' do
    describe '.with_feature_available_in_plan', :saas do
      let(:starter_feature) { :audit_events }
      let(:premium_feature) { :epics }
      let(:ultimate_feature) { :dast }

      context 'Bronze plan has Starter features' do
        let!(:bronze_namespace) { create(:namespace_with_plan, plan: :bronze_plan) }

        it 'returns namespaces with plan' do
          create(:namespace_with_plan, plan: :free_plan)

          expect(described_class.with_feature_available_in_plan(starter_feature)).to match_array([bronze_namespace])
        end

        it 'includes namespace from higher plans' do
          ultimate_namespace = create(:namespace_with_plan, plan: :ultimate_plan)

          expect(described_class.with_feature_available_in_plan(starter_feature))
            .to include(ultimate_namespace)
        end
      end

      context 'Silver, Premium and Premium_trial plans have Premium license features' do
        let!(:silver_namespace) { create(:namespace_with_plan, plan: :silver_plan) }
        let!(:premium_namespace) { create(:namespace_with_plan, plan: :premium_plan) }
        let!(:premium_trial_namespace) { create(:namespace_with_plan, plan: :premium_trial_plan) }
        let!(:not_included_namespace) { create(:namespace_with_plan, plan: :bronze_plan) }

        it 'returns namespaces with matching plans' do
          expect(described_class.with_feature_available_in_plan(premium_feature))
            .to contain_exactly(silver_namespace, premium_namespace, premium_trial_namespace)
        end

        it 'includes namespace from higher plans' do
          ultimate_namespace = create(:namespace_with_plan, plan: :ultimate_plan)

          expect(described_class.with_feature_available_in_plan(premium_feature))
            .to include(ultimate_namespace)
        end
      end

      context 'Gold, Ultimate, Ultimate_trial and OpenSource plans have Ultimate license features' do
        let!(:gold_namespace) { create(:namespace_with_plan, plan: :gold_plan) }
        let!(:ultimate_namespace) { create(:namespace_with_plan, plan: :ultimate_plan) }
        let!(:ultimate_trial_namespace) { create(:namespace_with_plan, plan: :ultimate_trial_plan) }
        let!(:opensource_namespace) { create(:namespace_with_plan, plan: :opensource_plan) }

        it 'returns namespaces with matching plans' do
          create(:gitlab_subscription, :bronze, namespace: namespace)

          expect(described_class.with_feature_available_in_plan(ultimate_feature))
            .to contain_exactly(gold_namespace, ultimate_namespace, ultimate_trial_namespace, opensource_namespace)
        end
      end

      context 'when no namespace matches the feature' do
        let!(:bronze_namespace) { create(:namespace_with_plan, plan: :bronze_plan) }
        let!(:silver_namespace) { create(:namespace_with_plan, plan: :silver_plan) }

        it 'returns an empty list' do
          expect(described_class.with_feature_available_in_plan(ultimate_feature)).to be_empty
        end
      end
    end

    describe '.join_gitlab_subscription', :saas do
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

    describe '.not_in_active_trial', :saas do
      let_it_be(:namespaces) do
        [
          create(:namespace),
          create(:namespace_with_plan),
          create(:namespace_with_plan, trial_ends_on: Date.yesterday)
        ]
      end

      it 'is consistent with !trial_active? method' do
        namespaces.each do |ns|
          consistent = described_class.not_in_active_trial.include?(ns) == !ns.trial_active?

          expect(consistent).to be true
        end
      end
    end

    describe '.in_default_plan', :saas do
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

    describe '.eligible_for_trial', :saas do
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

  describe 'keeping elasticsearch up to date' do
    it 'includes Elastic::NamespaceUpdate concern' do
      expect(described_class).to include_module(Elastic::NamespaceUpdate)
    end
  end

  describe 'after_commit :sync_name_with_customers_dot' do
    let(:owner) { create(:user) }
    let(:namespace) { create(:group) }
    let(:privatized_by_abuse_automation) { false }

    subject(:update_namespace) { namespace.update!(attributes) }

    before do
      allow(Gitlab).to receive(:com?).and_return(true)
      allow(owner).to receive(:privatized_by_abuse_automation?)
        .and_return(privatized_by_abuse_automation)
    end

    shared_examples 'no sync' do
      it 'does not trigger a sync with CustomersDot' do
        expect(::Namespaces::SyncNamespaceNameWorker).not_to receive(:perform_async)

        update_namespace
      end
    end

    shared_examples 'sync' do
      it 'triggers a name sync with CustomersDot' do
        expect(::Namespaces::SyncNamespaceNameWorker).to receive(:perform_async)
          .with(namespace.id).once

        update_namespace
      end
    end

    context 'when the name is not updated' do
      let(:attributes) { { path: 'Foo' } }

      before do
        namespace.add_owner(owner)
      end

      include_examples 'no sync'
    end

    context 'when the name is updated' do
      let(:attributes) { { name: 'Foo' } }

      context 'when not on Gitlab.com?' do
        before do
          allow(Gitlab).to receive(:com?).and_return(false)
        end

        include_examples 'no sync'
      end

      context 'when project namespace' do
        let(:namespace) { create(:project_namespace, owner: owner) }

        context 'when the owner is privatized by abuse automation' do
          let(:privatized_by_abuse_automation) { true }

          include_examples 'no sync'
        end

        context 'when the owner is not privatized by abuse automation' do
          include_examples 'no sync'
        end
      end

      context 'when group namespace' do
        before do
          namespace.add_owner(owner)
        end

        context 'when the owner is privatized by abuse automation' do
          let(:privatized_by_abuse_automation) { true }

          include_examples 'sync'
        end

        context 'when the owner is not privatized by abuse automation' do
          include_examples 'sync'
        end
      end

      context 'when user namespace' do
        let(:namespace) { create(:namespace, owner: owner) }

        context 'when the owner is privatized by abuse automation' do
          let(:privatized_by_abuse_automation) { true }

          include_examples 'no sync'
        end

        context 'when the owner is not privatized by abuse automation' do
          include_examples 'sync'
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

  describe '#feature_available?', :saas do
    subject { group.licensed_feature_available?(feature) }

    it_behaves_like 'feature available'
  end

  describe '#feature_available_non_trial?', :saas do
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

      context 'with a subgroup' do
        let(:subgroup) { create(:group, parent: group) }

        it 'feature is not available for the subgroup' do
          expect(subgroup.feature_available_non_trial?(feature)).to be_falsey
        end
      end
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
        limits = subject.attributes.except('id', 'plan_id', 'dashboard_limit_enabled_at')
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
            ci_pipeline_size: 2,
            ci_active_jobs: 3)
        end

        it { is_expected.to eq(default_limits) }
      end

      context 'when "free" plan is defined in the system', :saas do
        let!(:free_plan) { create(:free_plan) }

        context 'when no limits are set' do
          it_behaves_like 'uses an implied configuration'
        end

        context 'when limits are set for the free plan' do
          let!(:free_limits) do
            create(:plan_limits,
              plan: free_plan,
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

  describe '#paid?', :saas do
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

  describe '#actual_plan' do
    context 'when namespace does not have a subscription associated' do
      it 'generates a subscription and returns default plan' do
        expect(namespace.actual_plan).to eq(Plan.default)

        expect(namespace.gitlab_subscription).to be_nil
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
            let!(:free_plan) { create(:free_plan) }

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
            let!(:free_plan) { create(:free_plan) }

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

  describe '#billed_user_ids' do
    let(:user) { create(:user) }

    it 'returns 1' do
      expect(user.namespace.billed_user_ids.keys).to eq(
        [
          :user_ids,
          :group_member_user_ids,
          :project_member_user_ids,
          :shared_group_user_ids,
          :shared_project_user_ids
        ])
      expect(user.namespace.billed_user_ids[:user_ids]).to eq([user.id])
    end
  end

  describe '#billable_members_count' do
    let(:user) { create(:user) }

    it 'returns 1' do
      expect(user.namespace.billable_members_count).to eq(1)
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
        security_features = [
          :sast, :secret_detection, :dast, :dependency_scanning, :container_scanning,
          :cluster_image_scanning, :coverage_fuzzing, :api_fuzzing
        ]

        stub_licensed_features(security_features.index_with { false })
      end

      it { is_expected.to be false }
    end
  end

  describe '#ingest_sbom_reports_available?' do
    subject { namespace.ingest_sbom_reports_available? }

    context 'when at least one sbom-related feature is available' do
      where(:feature) { [:container_scanning, :dependency_scanning, :license_scanning] }

      before do
        stub_licensed_features(feature => true)
      end

      with_them do
        it { is_expected.to be true }
      end
    end

    context 'when sbom-related features are not available' do
      it { is_expected.to be false }
    end
  end

  describe '#over_storage_limit?', :saas do
    let_it_be(:namespace) { create(:namespace_with_plan, plan: :ultimate_plan) }

    before_all do
      create(:namespace_root_storage_statistics, namespace: namespace)
    end

    before do
      enforce_namespace_storage_limit(namespace)
      set_storage_size_limit(namespace, megabytes: 10)
    end

    it 'returns true if the namespace is over the storage limit', :saas do
      set_used_storage(namespace, megabytes: 11)

      expect(namespace.over_storage_limit?).to eq(true)
    end

    it 'returns false if the namespace storage equals the limit', :saas do
      set_used_storage(namespace, megabytes: 10)

      expect(namespace.over_storage_limit?).to eq(false)
    end

    it 'returns false if the namespace is under the storage limit', :saas do
      set_used_storage(namespace, megabytes: 9)

      expect(namespace.over_storage_limit?).to eq(false)
    end
  end

  describe '#read_only?' do
    let(:namespace) { build(:namespace) }

    where(:over_storage_limit, :over_free_user_limit, :result) do
      false           | false              | false
      false           | true               | true
      true            | false              | true
      true            | true               | true
    end

    subject { namespace.read_only? }

    with_them do
      before do
        allow(namespace).to receive(:over_storage_limit?).and_return(over_storage_limit)
        allow_next_instance_of(::Namespaces::FreeUserCap::Enforcement, namespace) do |instance|
          allow(instance).to receive(:over_limit?).and_return(over_free_user_limit)
        end
      end

      it { is_expected.to eq(result) }
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

  describe '#namespace_limit', feature_category: :consumables_cost_management do
    let_it_be(:parent) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: parent) }

    context 'when there is a parent namespace' do
      subject(:namespace_limit) { subgroup.namespace_limit }

      context 'with a namespace limit' do
        it 'returns the parent namespace limit' do
          parent_limit = create(:namespace_limit, namespace: parent)

          expect(namespace_limit).to eq parent_limit
          expect(namespace_limit).to be_persisted
        end
      end

      context 'with no namespace limit' do
        it 'builds namespace limit' do
          parent.namespace_limit.destroy!

          expect(namespace_limit).to be_present
          expect(namespace_limit).not_to be_persisted
        end
      end
    end

    context 'when there is no parent ancestor' do
      context 'for personal namespaces' do
        let_it_be(:namespace) { create(:namespace) }

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
            namespace.namespace_limit.destroy!

            expect(namespace_limit).to be_present
            expect(namespace_limit).not_to be_persisted
          end
        end
      end

      context 'for groups' do
        subject(:namespace_limit) { parent.namespace_limit }

        context 'with a namespace limit' do
          it 'returns the namespace limit' do
            limit = create(:namespace_limit, namespace: parent)

            expect(namespace_limit).to be_persisted
            expect(namespace_limit).to eq limit
          end
        end

        context 'with no namespace limit' do
          it 'builds namespace limit' do
            parent.namespace_limit.destroy!

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

  describe '#root_storage_size', :saas do
    let_it_be(:namespace) { create(:namespace) }

    subject(:root_storage_size) { namespace.root_storage_size }

    context 'when namespace storage limits are enabled' do
      before do
        enforce_namespace_storage_limit(namespace)
      end

      it 'returns an instance of RootSize' do
        expect(root_storage_size).to be_an_instance_of(::Namespaces::Storage::RootSize)
      end
    end

    context 'when namespace storage limits are disabled' do
      before do
        stub_application_setting(enforce_namespace_storage_limit: false)
        stub_application_setting(automatic_purchased_storage_allocation: false)
        stub_feature_flags(
          namespace_storage_limit: false,
          enforce_storage_limit_for_paid: false,
          enforce_storage_limit_for_free: false,
          namespace_storage_limit_bypass_date_check: false
        )
      end

      it 'returns an instance of RootExcessSize' do
        expect(root_storage_size).to be_an_instance_of(::Namespaces::Storage::RootExcessSize)
      end
    end

    context 'when namespace storage limits are disabled and automatic_purchased_storage_allocation is enabled' do
      before do
        stub_application_setting(enforce_namespace_storage_limit: false)
        stub_application_setting(automatic_purchased_storage_allocation: true)
        stub_feature_flags(
          namespace_storage_limit: false,
          enforce_storage_limit_for_paid: false,
          enforce_storage_limit_for_free: false,
          namespace_storage_limit_bypass_date_check: false
        )
      end

      it 'returns an instance of RootExcessSize' do
        expect(root_storage_size).to be_an_instance_of(::Namespaces::Storage::RootExcessSize)
      end
    end

    context 'when namespace storage limits are enabled for free namespaces and disabled for paid' do
      before do
        stub_application_setting(enforce_namespace_storage_limit: true)
        stub_application_setting(automatic_purchased_storage_allocation: true)
        stub_const('::EE::Gitlab::Namespaces::Storage::Enforcement::EFFECTIVE_DATE', 2.years.ago.to_date)
        stub_const('::EE::Gitlab::Namespaces::Storage::Enforcement::ENFORCEMENT_DATE', 1.year.ago.to_date)
        stub_feature_flags(
          namespace_storage_limit: true,
          enforce_storage_limit_for_paid: false,
          enforce_storage_limit_for_free: true,
          namespace_storage_limit_bypass_date_check: false
        )
      end

      it 'returns an instance of RootSize for a free namespace' do
        expect(root_storage_size).to be_an_instance_of(::Namespaces::Storage::RootSize)
      end

      it 'returns an instance of RootExcessSize for a paid namespace' do
        paid_namespace = create(:namespace_with_plan, plan: :ultimate_plan)

        expect(paid_namespace.root_storage_size).to be_an_instance_of(::Namespaces::Storage::RootExcessSize)
      end
    end
  end

  describe '#user_cap_available?' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:subgroup) {  create(:group, parent: namespace) }

    let(:gitlab_com?) { true }

    subject(:user_cap_available?) { namespace.user_cap_available? }

    before do
      allow(::Gitlab).to receive(:com?).and_return(gitlab_com?)
    end

    context 'when not on Gitlab.com' do
      let(:gitlab_com?) { false }

      it { is_expected.to be false }
    end

    context 'when :saas_user_caps is disabled' do
      before do
        stub_feature_flags(saas_user_caps: false)
      end

      it { is_expected.to be false }
    end

    context 'when :saas_user_caps is enabled' do
      before do
        stub_feature_flags(saas_user_caps: true)
      end

      it { is_expected.to be true }

      context 'when the namespace is not a group' do
        let(:user) { create(:user) }
        let(:namespace) { user.namespace }

        it { is_expected.to be false }
      end
    end
  end

  describe '#capacity_left_for_user?' do
    let(:namespace) { build(:namespace) }

    subject { namespace.capacity_left_for_user?(anything) }

    it { is_expected.to eq(true) }
  end

  describe '#exclude_guests?' do
    let(:namespace) { build(:namespace) }

    it 'returns false' do
      expect(namespace.exclude_guests?).to eq(false)
    end
  end

  describe '#all_security_orchestration_policy_configurations' do
    subject { child_group_2.all_security_orchestration_policy_configurations }

    let!(:parent_group) { create(:group) }
    let!(:child_group) { create(:group, parent: parent_group) }
    let!(:child_group_2) { create(:group, parent: child_group) }

    let!(:parent_security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :namespace, namespace: parent_group) }
    let!(:child_security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :namespace, namespace: child_group_2) }

    context 'when configuration is invalid' do
      before do
        allow_next_found_instances_of(Security::OrchestrationPolicyConfiguration, 2) do |configuration|
          allow(configuration).to receive(:policy_configuration_valid?).and_return(false)
        end
      end

      it 'returns empty list' do
        expect(subject).to be_empty
      end
    end

    context 'when configuration is valid' do
      before do
        allow_next_found_instances_of(Security::OrchestrationPolicyConfiguration, 2) do |configuration|
          allow(configuration).to receive(:policy_configuration_valid?).and_return(true)
        end
      end

      it 'returns security policy configurations for all valid parent groups' do
        expect(subject).to match_array(
          [
            parent_security_orchestration_policy_configuration,
            child_security_orchestration_policy_configuration
          ]
        )
      end
    end
  end

  describe '#all_inherited_security_orchestration_policy_configurations' do
    subject { child_group_2.all_inherited_security_orchestration_policy_configurations }

    let_it_be(:parent_group) { create(:group) }
    let_it_be(:child_group) { create(:group, parent: parent_group) }
    let_it_be(:child_group_2) { create(:group, parent: child_group) }

    let_it_be(:parent_security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :namespace, namespace: parent_group) }
    let_it_be(:child_security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, :namespace, namespace: child_group_2) }

    context 'when there is no configuration for group ancestors' do
      subject { parent_group.all_inherited_security_orchestration_policy_configurations }

      it 'returns empty list' do
        expect(subject).to be_empty
      end
    end

    context 'when configuration is invalid' do
      before do
        allow_next_found_instances_of(Security::OrchestrationPolicyConfiguration, 2) do |configuration|
          allow(configuration).to receive(:policy_configuration_valid?).and_return(false)
        end
      end

      it 'returns empty list' do
        expect(subject).to be_empty
      end
    end

    context 'when configuration is valid' do
      before do
        allow_next_found_instances_of(Security::OrchestrationPolicyConfiguration, 2) do |configuration|
          allow(configuration).to receive(:policy_configuration_valid?).and_return(true)
        end
      end

      it 'returns security policy configurations for all valid parent groups' do
        expect(subject).to match_array(
          [
            parent_security_orchestration_policy_configuration
          ]
        )
      end
    end
  end

  describe '#all_projects_pages_domains' do
    let_it_be(:namespace) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: namespace) }
    let_it_be(:project1) { create(:project, group: namespace) }
    let_it_be(:project2) { create(:project, group: subgroup) }

    let!(:verified_domain) { create(:pages_domain, project: project1) }
    let!(:unverified_domain) { create(:pages_domain, :unverified, project: project2) }

    it 'finds all pages domains by default' do
      expect(namespace.all_projects_pages_domains).to match_array([verified_domain, unverified_domain])
    end

    it 'finds only verified domains when param is true' do
      expect(namespace.all_projects_pages_domains(only_verified: true)).to match_array(verified_domain)
    end

    context 'when projects are outside the top-level group hierarchy' do
      before do
        outside_namespace = create(:group)
        outside_project = create(:project, group: outside_namespace)
        create(:pages_domain, project: outside_project)
      end

      it 'does not include the outside domain' do
        expect(namespace.all_projects_pages_domains).to match_array([verified_domain, unverified_domain])
      end
    end
  end

  describe '#domain_verification_available?' do
    let(:namespace) { create(:group) }

    context 'when the feature is not licensed' do
      before do
        stub_licensed_features(domain_verification: false)
      end

      it 'is not available' do
        expect(namespace.domain_verification_available?).to eq(false)
      end

      context 'on GitLab.com', :saas do
        it 'is not available' do
          expect(namespace.domain_verification_available?).to eq(false)
        end
      end
    end

    context 'when the feature is licensed' do
      before do
        stub_licensed_features(domain_verification: true)
      end

      it 'is not available' do
        expect(namespace.domain_verification_available?).to eq(false)
      end

      context 'on GitLab.com', :saas do
        it 'is available' do
          expect(namespace.domain_verification_available?).to eq(true)
        end

        context 'with a subgroup' do
          let(:subgroup) { create(:group, :nested) }

          it 'is not available' do
            expect(subgroup.domain_verification_available?).to eq(false)
          end
        end
      end
    end
  end

  describe '#custom_roles_enabled?', feature_category: :system_access do
    let_it_be(:namespace) { create(:group) }

    let(:licensed_feature_available) { true }

    before do
      stub_licensed_features(custom_roles: licensed_feature_available)
    end

    subject { namespace.custom_roles_enabled? }

    it { is_expected.to eq true }

    context 'when licensed feature is not available' do
      let(:licensed_feature_available) { false }

      it { is_expected.to eq false }
    end

    context 'when sub-group' do
      let(:subgroup) { create(:group, parent: namespace) }

      subject { subgroup.custom_roles_enabled? }

      it { is_expected.to eq false }
    end
  end

  describe '#allow_stale_runner_pruning?' do
    subject { namespace.allow_stale_runner_pruning? }

    let(:ci_cd_settings) { ::NamespaceCiCdSetting.find_or_initialize_by(namespace_id: namespace.id) }

    it { is_expected.to eq false }

    context 'with ci_cd_setting.allow_stale_runner_pruning set to false' do
      before do
        ci_cd_settings.update!(allow_stale_runner_pruning: false)
      end

      it { is_expected.to eq false }
    end

    context 'with ci_cd_setting.allow_stale_runner_pruning set to true' do
      before do
        ci_cd_settings.update!(allow_stale_runner_pruning: true)
      end

      it { is_expected.to eq true }
    end
  end

  describe '#allow_stale_runner_pruning=' do
    context 'with no existing ci_cd_setting association' do
      context 'when value is set to false' do
        it 'does not build new association' do
          namespace.update!(allow_stale_runner_pruning: false)
          namespace.reload

          expect(namespace.ci_cd_settings).to be_nil
        end
      end

      context 'when value is set to true' do
        it 'builds association' do
          namespace.update!(allow_stale_runner_pruning: true)
          namespace.reload

          expect(namespace.ci_cd_settings).not_to be_nil
          expect(namespace.ci_cd_settings.allow_stale_runner_pruning?).to eq true
        end
      end
    end

    context 'with existing ci_cd_setting association' do
      let(:ci_cd_settings) do
        ::NamespaceCiCdSetting.find_or_initialize_by(namespace_id: namespace.id, allow_stale_runner_pruning: false)
      end

      context 'when value is set to true' do
        it 'updates association' do
          namespace.update!(allow_stale_runner_pruning: true)
          namespace.reload

          expect(namespace.ci_cd_settings.allow_stale_runner_pruning?).to eq true
        end
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
