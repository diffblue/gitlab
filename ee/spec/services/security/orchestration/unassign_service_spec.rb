# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Orchestration::UnassignService do
  let_it_be(:project, reload: true) { create(:project, :with_security_orchestration_policy_configuration) }
  let_it_be(:project_without_policy_project, reload: true) { create(:project) }

  let(:service) { described_class.new(project, nil) }

  describe '#execute' do
    subject(:result) { service.execute }

    context 'when policy project is assigned to a project' do
      let(:service) { described_class.new(project, nil) }

      it 'unassigns policy project from the project', :aggregate_failures do
        expect(result).to be_success
        expect(project.security_orchestration_policy_configuration).to be_destroyed
      end
    end

    context 'when policy project is not assigned to a project' do
      let(:service) { described_class.new(project_without_policy_project, nil) }

      it 'respond with an error', :aggregate_failures do
        expect(result).not_to be_success
        expect(result.message).to eq("Policy project doesn't exist")
      end
    end
  end
end
