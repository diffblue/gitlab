# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ProjectCreateService do
  describe '#execute' do
    let_it_be_with_refind(:project) { create(:project) }

    let_it_be(:owner) { create(:user) }
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:developer) { create(:user) }

    let(:current_user) { container.first_owner }
    let(:container) { project }

    subject(:service) { described_class.new(container: container, current_user: current_user) }

    context 'when security_orchestration_policies_configuration does not exist for project' do
      before do
        project.add_maintainer(maintainer)
        project.add_developer(developer)
      end

      it 'creates policy project with maintainers and developers from target project as developers', :aggregate_failures do
        response = service.execute

        policy_project = response[:policy_project]
        expect(project.reload.security_orchestration_policy_configuration.security_policy_management_project).to eq(policy_project)
        expect(policy_project.namespace).to eq(project.namespace)
        expect(policy_project.team.developers).to contain_exactly(maintainer, developer)
        expect(policy_project.container_registry_access_level).to eq(ProjectFeature::DISABLED)
        expect(policy_project.repository.readme.data).to include('# Security Policy Project for')
        expect(policy_project.repository.readme.data).to include('## Default branch protection settings')
      end
    end

    context 'when security_orchestration_policies_configuration does not exist for namespace' do
      let(:group) { create(:group) }
      let(:container) { group }

      before do
        group.add_owner(owner)
        group.add_maintainer(maintainer)
        group.add_developer(developer)
      end

      it 'creates policy project with maintainers and developers from target group as developers', :aggregate_failures do
        response = service.execute

        policy_project = response[:policy_project]
        expect(group.reload.security_orchestration_policy_configuration.security_policy_management_project).to eq(policy_project)
        expect(policy_project.namespace).to eq(group)
        expect(policy_project.owner).to eq(group)
        expect(MembersFinder.new(policy_project, nil).execute.map(&:user)).to contain_exactly(owner, maintainer, developer)
        expect(policy_project.container_registry_access_level).to eq(ProjectFeature::DISABLED)
        expect(policy_project.repository.readme.data).to include('# Security Policy Project for')
        expect(policy_project.repository.readme.data).to include('## Default branch protection settings')
      end
    end

    context 'when adding users to security policy project fails' do
      let(:current_user) { project.first_owner }

      before do
        project.add_maintainer(maintainer)

        errors = ActiveModel::Errors.new(ProjectMember.new).tap { |e| e.add(:source, "cannot be nil") }
        error_member = ProjectMember.new
        allow(error_member).to receive(:errors).and_return(errors)
        allow(service).to receive(:add_members).and_return([error_member])
      end

      it 'returns error' do
        response = service.execute

        expect(response[:status]).to eq(:error)
        expect(response[:message]).to eq('Project was created and assigned as security policy project, but failed adding users to the project.')
      end
    end

    context 'when project creation fails' do
      let(:current_user) { create(:user) }

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
