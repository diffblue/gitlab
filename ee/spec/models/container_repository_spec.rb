# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRepository, :saas do
  describe '.with_target_import_tier' do
    let_it_be(:project) { create(:project) }
    let_it_be(:valid_container_repository) { create(:container_repository, project: project) }

    let_it_be(:gitlab_namespace) { create(:namespace, path: 'gitlab-org') }
    let_it_be(:gitlab_project) { create(:project, namespace: gitlab_namespace) }
    let_it_be(:gitlab_container_repository) { create(:container_repository, project: gitlab_project) }

    let_it_be(:ultimate_project) { create(:project) }
    let_it_be(:ultimate_container_repository) { create(:container_repository, project: ultimate_project) }

    let(:subscription) { create(:gitlab_subscription, :premium, namespace: project.namespace) }
    let(:ultimate_subscription) { create(:gitlab_subscription, :ultimate, namespace: ultimate_project.namespace) }

    subject { described_class.with_target_import_tier }

    before do
      stub_application_setting(container_registry_import_target_plan: subscription.hosted_plan.name)
    end

    context 'limit_gitlab_org enabled' do
      it { is_expected.to contain_exactly(gitlab_container_repository) }
    end

    context 'limit_gitlab_org disabled' do
      before do
        stub_feature_flags(container_registry_migration_limit_gitlab_org: false)
      end

      it { is_expected.to contain_exactly(valid_container_repository) }
    end
  end

  describe '.ready_for_import' do
    include_context 'importable repositories'

    let_it_be(:ultimate_project) { create(:project) }
    let_it_be(:ultimate_container_repository) { create(:container_repository, project: ultimate_project, created_at: 2.days.ago) }

    let_it_be(:subscription) { create(:gitlab_subscription, :premium, namespace: project.namespace) }
    let_it_be(:denied_subscription) { create(:gitlab_subscription, :premium, namespace: denied_project.namespace) }
    let_it_be(:ultimate_subscription) { create(:gitlab_subscription, :ultimate, namespace: ultimate_project.namespace) }

    subject { described_class.ready_for_import }

    before do
      stub_application_setting(container_registry_import_target_plan: subscription.hosted_plan.name)
    end

    it { is_expected.to contain_exactly(valid_container_repository, valid_container_repository2) }
  end
end
