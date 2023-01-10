# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environment, :use_clean_rails_memory_store_caching do
  include ReactiveCachingHelpers

  let_it_be_with_refind(:group) { create(:group) }
  let_it_be_with_refind(:project) { create(:project, :repository, group: group) }
  let_it_be_with_refind(:environment) { create(:environment, project: project) }

  it { is_expected.to have_many(:dora_daily_metrics) }

  describe '.deployed_to_cluster' do
    let!(:environment) { create(:environment) }

    context 'when there is no deployment' do
      let(:cluster) { create(:cluster) }

      it 'returns nothing' do
        expect(described_class.deployed_to_cluster(cluster)).to be_empty
      end
    end

    context 'when there is a deployment for the cluster' do
      let(:cluster) { last_deployment.cluster }

      let(:last_deployment) do
        create(:deployment, :success, :on_cluster, environment: environment)
      end

      it 'returns the environment for the last deployment' do
        expect(described_class.deployed_to_cluster(cluster)).to eq([environment])
      end
    end

    context 'when there is a non-cluster deployment' do
      let(:cluster) { create(:cluster) }

      before do
        create(:deployment, :success, environment: environment)
      end

      it 'returns nothing' do
        expect(described_class.deployed_to_cluster(cluster)).to be_empty
      end
    end

    context 'when the non-cluster deployment is latest' do
      let(:cluster) { create(:cluster) }

      before do
        create(:deployment, :success, cluster: cluster, environment: environment)
        create(:deployment, :success, environment: environment)
      end

      it 'returns nothing' do
        expect(described_class.deployed_to_cluster(cluster)).to be_empty
      end
    end
  end

  describe '#protected?' do
    subject { environment.protected? }

    before do
      stub_licensed_features(protected_environments: feature_available)
    end

    context 'when Protected Environments feature is not available on the project' do
      let(:feature_available) { false }

      it { is_expected.to be_falsy }
    end

    context 'when Protected Environments feature is available on the project' do
      let(:feature_available) { true }

      context 'when the environment is protected' do
        before do
          create(:protected_environment, name: environment.name, project: project)
        end

        it { is_expected.to be_truthy }
      end

      context 'when the environment is not protected' do
        it { is_expected.to be_falsy }
      end
    end
  end

  describe '#protected_from?' do
    let(:user) { create(:user) }
    let(:protected_environment) { create(:protected_environment, :maintainers_can_deploy, name: environment.name, project: project) }

    subject { environment.protected_from?(user) }

    before do
      stub_licensed_features(protected_environments: feature_available)
    end

    context 'when Protected Environments feature is not available on the project' do
      let(:feature_available) { false }

      it { is_expected.to be_falsy }
    end

    context 'when Protected Environments feature is available on the project' do
      let(:feature_available) { true }

      context 'when the environment is not protected' do
        it { is_expected.to be_falsy }
      end

      context 'when the user is nil' do
        let(:user) {}

        it { is_expected.to be_truthy }
      end

      context 'when environment is protected and user dont have access to it' do
        before do
          protected_environment
        end

        it { is_expected.to be_truthy }
      end

      context 'when environment is protected and user have access to it' do
        before do
          protected_environment.deploy_access_levels.create!(user: user)
        end

        it { is_expected.to be_falsy }

        it 'caches result', :request_store do
          environment.protected_from?(user)

          expect { environment.protected_from?(user) }.not_to exceed_query_limit(0)
        end
      end
    end
  end

  describe '#protected_by?' do
    let(:user) { create(:user) }
    let(:protected_environment) { create(:protected_environment, :maintainers_can_deploy, name: environment.name, project: project) }

    subject { environment.protected_by?(user) }

    before do
      stub_licensed_features(protected_environments: feature_available)
    end

    context 'when Protected Environments feature is not available on the project' do
      let(:feature_available) { false }

      it { is_expected.to be_falsy }
    end

    context 'when Protected Environments feature is available on the project' do
      let(:feature_available) { true }

      context 'when the environment is not protected' do
        it { is_expected.to be_falsy }
      end

      context 'when the user is nil' do
        let(:user) {}

        it { is_expected.to be_falsy }
      end

      context 'when environment is protected and user dont have access to it' do
        before do
          protected_environment
        end

        it { is_expected.to be_falsy }
      end

      context 'when environment is protected and user have access to it' do
        before do
          protected_environment.deploy_access_levels.create!(user: user)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#without_protected' do
    subject { described_class.without_protected(project) }

    context 'when protected by project' do
      before do
        create(:protected_environment, name: environment.name, project: project)
      end

      it { is_expected.to be_empty }
    end

    context 'when protected by group' do
      before do
        create(:protected_environment, name: environment.tier, project: nil, group: project.group)
      end

      it { is_expected.to be_empty }
    end
  end

  describe '#reactive_cache_updated' do
    let(:mock_store) { double }

    subject { environment.reactive_cache_updated }

    it 'expires the environments path for the project' do
      expect(::Gitlab::EtagCaching::Store).to receive(:new).and_return(mock_store)
      expect(mock_store).to receive(:touch).with(::Gitlab::Routing.url_helpers.project_environments_path(project, format: :json))

      subject
    end

    context 'with a group cluster' do
      let(:cluster) { create(:cluster, :group) }

      before do
        create(:deployment, :success, environment: environment, cluster: cluster)
      end

      it 'expires the environments path for the group cluster' do
        expect_next_instance_of(Gitlab::EtagCaching::Store) do |store|
          expect(store).to receive(:touch)
            .with(::Gitlab::Routing.url_helpers.project_environments_path(project, format: :json))
            .and_call_original

          expect(store).to receive(:touch)
            .with(::Gitlab::Routing.url_helpers.environments_group_cluster_path(cluster.group, cluster))
            .and_call_original
        end

        subject
      end
    end

    context 'with an instance cluster' do
      let(:cluster) { create(:cluster, :instance) }

      before do
        create(:deployment, :success, environment: environment, cluster: cluster)
      end

      it 'expires the environments path for the group cluster' do
        expect_next_instance_of(Gitlab::EtagCaching::Store) do |store|
          expect(store).to receive(:touch)
            .with(::Gitlab::Routing.url_helpers.project_environments_path(project, format: :json))
            .and_call_original

          expect(store).to receive(:touch)
            .with(::Gitlab::Routing.url_helpers.environments_admin_cluster_path(cluster))
            .and_call_original
        end

        subject
      end
    end
  end

  describe '#needs_approval?' do
    subject { environment.needs_approval? }

    context 'when Protected Environments feature is available' do
      before do
        stub_licensed_features(protected_environments: true)
      end

      context 'with unified access level' do
        before do
          create(:protected_environment, name: environment.name, project: project, required_approval_count: required_approval_count)
        end

        context 'with some approvals required' do
          let(:required_approval_count) { 1 }

          it { is_expected.to be_truthy }
        end

        context 'with no approvals required' do
          let(:required_approval_count) { 0 }

          it { is_expected.to be_falsey }
        end
      end

      context 'with multi access levels' do
        let!(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

        context 'with some approvals required' do
          let!(:approval_rule) do
            create(:protected_environment_approval_rule, :maintainer_access, protected_environment: protected_environment)
          end

          it { is_expected.to be_truthy }
        end

        context 'with no approvals required' do
          it { is_expected.to be_falsey }
        end
      end
    end

    context 'when Protected Environments feature is not available' do
      before do
        stub_licensed_features(protected_environments: false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#required_approval_count' do
    subject { environment.required_approval_count }

    context 'when Protected Environments feature is not available' do
      before do
        stub_licensed_features(protected_environments: false)
      end

      it { is_expected.to eq(0) }
    end

    context 'when Protected Environments feature is available' do
      before do
        stub_licensed_features(protected_environments: true)
      end

      context 'and no associated protected environments exist' do
        it { is_expected.to eq(0) }
      end

      context 'with unified approval setting' do
        context 'with one associated protected environment' do
          before do
            create(:protected_environment, name: environment.name, project: project, required_approval_count: 3)
          end

          it 'returns the required_approval_count of the protected environment' do
            expect(subject).to eq(3)
          end
        end

        context 'with multiple associated protected environments' do
          before do
            create(:protected_environment, name: environment.name, project: project, required_approval_count: 3)
            create(:protected_environment, name: environment.tier, project: nil, group: project.group, required_approval_count: 5)
          end

          it 'returns the highest required_approval_count of the protected environments' do
            expect(subject).to eq(5)
          end
        end
      end

      context 'with multiple approval rules' do
        let_it_be(:qa_group) { create(:group, name: 'QA') }
        let_it_be(:security_group) { create(:group, name: 'Security') }

        let_it_be(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

        before do
          create(:protected_environment_approval_rule, group_id: qa_group.id, protected_environment: protected_environment)
          create(:protected_environment_approval_rule, group_id: security_group.id, required_approvals: 2, protected_environment: protected_environment)
        end

        it 'returns the sum of required approvals for all approval rules' do
          expect(subject).to eq(3)
        end
      end
    end
  end

  describe '#has_approval_rules?' do
    subject { environment.has_approval_rules? }

    let_it_be(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

    it { is_expected.to eq(false) }

    context 'with approval rules' do
      let!(:approval_rule) { create(:protected_environment_approval_rule, :maintainer_access, protected_environment: protected_environment) }

      it { is_expected.to eq(true) }
    end
  end

  describe '#find_approval_rule_for' do
    subject { environment.find_approval_rule_for(user, represented_as: represented_as) }

    let_it_be(:qa_group) { create(:group, name: 'QA') }
    let_it_be(:security_group) { create(:group, name: 'Security') }
    let_it_be(:qa_user) { create(:user) }
    let_it_be(:security_user) { create(:user) }
    let_it_be(:super_user) { create(:user) }
    let_it_be(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

    let(:user) { qa_user }
    let(:represented_as) {}

    before_all do
      qa_group.add_developer(qa_user)
      qa_group.add_developer(super_user)
      security_group.add_developer(security_user)
      security_group.add_developer(super_user)
    end

    it { is_expected.to be_nil }

    context 'with approval rules' do
      let!(:approval_rule_for_qa) { create(:protected_environment_approval_rule, group: qa_group, protected_environment: protected_environment) }
      let!(:approval_rule_for_security) { create(:protected_environment_approval_rule, group: security_group, protected_environment: protected_environment) }

      context 'when user belongs to QA group' do
        let(:user) { qa_user }

        it { is_expected.to eq(approval_rule_for_qa) }
      end

      context 'when user belongs to Security group' do
        let(:user) { security_user }

        it { is_expected.to eq(approval_rule_for_security) }
      end

      context 'when user belongs to both groups' do
        let(:user) { super_user }

        it 'returns one of the rules' do
          expect([approval_rule_for_qa, approval_rule_for_security]).to include(subject)
        end

        context 'when represented as QA group' do
          let(:represented_as) { 'QA' }

          it { is_expected.to eq(approval_rule_for_qa) }
        end

        context 'when represented as Security group' do
          let(:represented_as) { 'Security' }

          it { is_expected.to eq(approval_rule_for_security) }
        end
      end
    end
  end
end
