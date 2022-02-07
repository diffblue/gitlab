# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environment, :use_clean_rails_memory_store_caching do
  include ReactiveCachingHelpers

  let(:project) { create(:project, :repository) }
  let(:environment) { create(:environment, project: project) }

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
        let(:user) { }

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
        let(:user) { }

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

    context 'when Protected Environments feature is not available' do
      before do
        stub_licensed_features(protected_environments: false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#required_approval_count' do
    subject { environment.required_approval_count }

    let_it_be(:project) { create(:project, group: create(:group)) }

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
  end
end
