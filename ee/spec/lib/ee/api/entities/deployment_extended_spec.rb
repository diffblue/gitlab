# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::API::Entities::DeploymentExtended do
  subject { ::API::Entities::DeploymentExtended.new(deployment).as_json }

  describe '#as_json' do
    let(:deployment) { create(:deployment, :blocked) }

    before do
      stub_licensed_features(protected_environments: true)
      create(:protected_environment, project_id: deployment.environment.project_id, name: deployment.environment.name, required_approval_count: 2)
      create(:deployment_approval, :approved, deployment: deployment)
    end

    it 'includes fields from deployment entity' do
      is_expected.to include(:id, :iid, :ref, :sha, :created_at, :updated_at, :user, :environment, :deployable, :status)
    end

    it 'includes pending_approval_count' do
      expect(subject[:pending_approval_count]).to eq(1)
    end

    it 'includes approvals', :aggregate_failures do
      expect(subject[:approvals].length).to eq(1)
      expect(subject.dig(:approvals, 0, :status)).to eq("approved")
    end
  end
end
