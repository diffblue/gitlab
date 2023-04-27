# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::AuthorizeProxyUserService, feature_category: :deployment_management do
  subject(:service_response) { service.execute }

  let(:service) { described_class.new(user, agent) }
  let(:user) { create(:user) }

  let_it_be(:organization) { create(:group) }
  let_it_be(:configuration_project) { create(:project, group: organization) }
  let_it_be(:agent) { create(:cluster_agent, name: 'the-agent', project: configuration_project) }
  let_it_be(:deployment_project) { create(:project, group: organization) }
  let_it_be(:deployment_group) { create(:group, parent: organization) }

  let(:user_access_config) do
    {
      'user_access' => {
        'access_as' => { 'user' => {} },
        'projects' => [{ 'id' => deployment_project.full_path }],
        'groups' => [{ 'id' => deployment_group.full_path }]
      }
    }
  end

  before do
    Clusters::Agents::Authorizations::UserAccess::RefreshService.new(agent, config: user_access_config).execute
  end

  it 'returns forbidden when user has no access to any project', :aggregate_failures do
    expect(service_response).to be_error
    expect(service_response.reason).to eq :forbidden
  end

  it "returns the user's authorizations when they have access", :aggregate_failures do
    deployment_project.add_member(user, :developer)
    deployment_group.add_member(user, :maintainer)

    expect(service_response).to be_success
    expect(service_response.payload[:access_as]).to eq({
      user: {
        projects: [{ id: deployment_project.id, roles: %i[guest reporter developer] }],
        groups: [{ id: deployment_group.id, roles: %i[guest reporter developer maintainer] }]
      }
    })
  end
end
