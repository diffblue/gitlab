# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::ProjectRecalculateService, "#execute", feature_category: :projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:security_policy_management_project) { create(:project, :repository) }

  let(:worker) { Security::ProcessScanResultPolicyWorker }

  subject(:execute) { described_class.new(project).execute }

  before do
    stub_licensed_features(security_orchestration_policies: true)

    allow_next_found_instances_of(Security::OrchestrationPolicyConfiguration, 3) do |instance|
      allow(instance).to receive(:policy_configuration_valid?).and_return(true)
    end
  end

  context "without associated policy configuration" do
    before do
      project.add_developer(user)
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
        project: project, security_policy_management_project: security_policy_management_project)
    end

    before do
      project.add_developer(user)
      project.project_authorizations.where(user: user).delete_all
      project.reset
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
        project.add_guest(user)
        project.project_authorizations.where(user: user).delete_all
      end

      it "does not recreate approval rules" do
        expect(worker).not_to receive(:perform_async)

        execute
      end
    end

    context "with group-level configuration" do
      let_it_be(:group) { create(:group) }

      before do
        project.group = group
        project.save!

        configuration.update!(project_id: nil, namespace_id: group.id)

        project.add_developer(user)
        project.project_authorizations.where(user: user).delete_all

        project.reload
      end

      it "recreates approval rules" do
        expect(worker).to receive(:perform_async).with(project.id, configuration.id)

        execute
      end
    end
  end
end
