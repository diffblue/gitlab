# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::RefreshAuthorizedProjectsService, "#execute", feature_category: :projects do
  include ExclusiveLeaseHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let(:worker) { Security::ProcessScanResultPolicyWorker }

  before do
    stub_licensed_features(security_orchestration_policies: true)

    allow_next_found_instances_of(Security::OrchestrationPolicyConfiguration, 3) do |instance|
      allow(instance).to receive(:policy_configuration_valid?).and_return(true)
    end
  end

  describe '#execute', :clean_gitlab_redis_shared_state do
    subject(:execute) { described_class.new(user).execute }

    context "without associated policy configuration" do
      before do
        group.add_developer(user)
        project.project_authorizations.where(user: user).delete_all
      end

      it "does not recreate approval rules" do
        expect(worker).not_to receive(:perform_async)

        execute
      end
    end

    context "with associated project-level policy configuration" do
      let!(:configuration) do
        project.security_orchestration_policy_configuration = create(:security_orchestration_policy_configuration,
          project: project)
      end

      before do
        group.add_developer(user)
        project.project_authorizations.where(user: user).delete_all
      end

      it "recreates approval rules" do
        expect(worker).to receive(:perform_async).with(project.id, configuration.id)

        execute
      end

      context "with feature disabled" do
        before do
          stub_licensed_features(security_orchestration_policies: false)
        end

        it "does not recreate approval rules" do
          expect(worker).not_to receive(:perform_async)

          execute
        end
      end

      context "with lower authorization levels" do
        before do
          group.add_guest(user)
          project.project_authorizations.where(user: user).delete_all
        end

        it "does not recreate approval rules" do
          expect(worker).not_to receive(:perform_async)

          execute
        end
      end
    end

    context "with group-level configuration" do
      let!(:configuration) do
        group.security_orchestration_policy_configuration = create(:security_orchestration_policy_configuration,
          :namespace, namespace: group)
      end

      before do
        group.add_developer(user)
        project.project_authorizations.where(user: user).delete_all
      end

      it "recreates approval rules" do
        expect(worker).to receive(:perform_async).with(project.id, configuration.id)

        execute
      end
    end
  end
end
