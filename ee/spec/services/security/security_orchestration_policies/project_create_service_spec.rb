# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ProjectCreateService do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { project.owner }

    subject(:service) { described_class.new(project: project, current_user: current_user) }

    context 'when security_orchestration_policies_configuration does not exist for project' do
      let_it_be(:maintainer) { create(:user) }

      before do
        project.add_maintainer(maintainer)
      end

      it 'creates new project' do
        response = service.execute

        policy_project = response[:policy_project]
        expect(project.security_orchestration_policy_configuration.security_policy_management_project).to eq(policy_project)
        expect(policy_project.namespace).to eq(project.namespace)
        expect(policy_project.protected_branches.map(&:name)).to contain_exactly(project.default_branch_or_main)
        expect(policy_project.protected_branches.first.merge_access_levels.map(&:access_level)).to eq([Gitlab::Access::MAINTAINER])
        expect(policy_project.protected_branches.first.push_access_levels.map(&:access_level)).to eq([Gitlab::Access::NO_ACCESS])
        expect(policy_project.team.developers).to contain_exactly(maintainer)
      end
    end

    context 'when protected branch already exists' do
      let_it_be(:project) { create(:project) }
      let_it_be(:current_user) { project.owner }
      let_it_be(:maintainer) { create(:user) }

      before do
        project.add_maintainer(maintainer)

        allow_next_instance_of(Project) do |instance|
          allow(instance).to receive_message_chain(:protected_branches, :find_by_name).and_return([ProtectedBranch.new])
        end

        protected_branch_service = instance_spy(ProtectedBranches::UpdateService)
        allow(ProtectedBranches::UpdateService).to receive(:new).and_return(protected_branch_service)
      end

      it 'updates protected branch' do
        service.execute

        expect(ProtectedBranches::UpdateService).to have_received(:new)
      end
    end

    context 'when protected branch does not exist' do
      let_it_be(:project) { create(:project) }
      let_it_be(:current_user) { project.owner }
      let_it_be(:maintainer) { create(:user) }

      before do
        project.add_maintainer(maintainer)

        protected_branch_service = instance_spy(ProtectedBranches::CreateService)
        allow(ProtectedBranches::CreateService).to receive(:new).and_return(protected_branch_service)
      end

      it 'creates protected branch' do
        service.execute

        expect(ProtectedBranches::CreateService).to have_received(:new)
      end
    end

    context 'when adding users to security policy project fails' do
      let_it_be(:project) { create(:project) }
      let_it_be(:current_user) { project.owner }
      let_it_be(:maintainer) { create(:user) }

      before do
        project.add_maintainer(maintainer)

        errors = ActiveModel::Errors.new(ProjectMember.new).tap { |e| e.add(:source, "cannot be nil") }
        allow_next_instance_of(ProjectMember) do |instance|
          allow(instance).to receive(:errors).and_return(errors)
        end
      end

      it 'returns error' do
        response = service.execute

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq('Project was created and assigned as security policy project, but failed adding users to the project.')
      end
    end

    context 'when project creation fails' do
      let_it_be(:project) { create(:project) }
      let_it_be(:current_user) { create(:user) }

      it 'returns error' do
        response = service.execute

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq('Namespace is not valid')
      end
    end

    context 'when security_orchestration_policies_configuration already exists for project' do
      let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }

      it 'returns error' do
        response = service.execute

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq('Security Policy project already exists.')
      end
    end
  end
end
