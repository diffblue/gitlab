# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeploymentEntity do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:deployment) { create(:deployment, :blocked, project: project, environment: environment) }
  let_it_be(:request) { EntityRequest.new(project: project, current_user: create(:user)) }

  subject { described_class.new(deployment, request: request).as_json }

  before do
    stub_licensed_features(protected_environments: true)
    create(:protected_environment, name: environment.name, project: project, required_approval_count: 3)
    create(:deployment_approval, deployment: deployment)
  end

  describe '#pending_approval_count' do
    it 'exposes pending_approval_count' do
      expect(subject[:pending_approval_count]).to eq(2)
    end
  end
end
