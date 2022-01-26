# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ProjectCreateService do
  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:current_user) { project.first_owner }

    subject(:service) { described_class.new(project: project, current_user: current_user) }

    context 'when security_orchestration_policies_configuration does not exist for project' do
      let_it_be(:maintainer) { create(:user) }
      let_it_be(:developer) { create(:user) }

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

    context 'when adding users to security policy project fails' do
      let_it_be(:project) { create(:project) }
      let_it_be(:current_user) { project.first_owner }
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
