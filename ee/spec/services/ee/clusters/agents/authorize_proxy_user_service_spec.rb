# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::AuthorizeProxyUserService, feature_category: :deployment_management do
  subject(:service_response) { service.execute }

  let(:service) { described_class.new(user, agent) }
  let(:user) { create(:user) }

  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }
  let_it_be(:user_access_config) do
    {
      'user_access' => {
        'access_as' => { 'user' => {} },
        'projects' => [{ 'id' => project.full_path }],
        'groups' => [{ 'id' => group.full_path }]
      }
    }
  end

  let_it_be(:configuration_project) do
    create(
      :project, :custom_repo,
      files: {
        ".gitlab/agents/the-agent/config.yaml" => user_access_config.to_yaml
      }
    )
  end

  let_it_be(:agent) { create(:cluster_agent, name: 'the-agent', project: configuration_project) }

  it 'returns forbidden when user has no access to any project', :aggregate_failures do
    expect(service_response).to be_error
    expect(service_response.reason).to eq :forbidden
  end

  it "returns the user's authorizations when they have access", :aggregate_failures do
    project.add_member(user, :developer)
    group.add_member(user, :maintainer)

    expect(service_response).to be_success
    expect(service_response.payload[:access_as]).to eq({
      user: {
        projects: [{ id: project.id, roles: %i[guest reporter developer] }],
        groups: [{ id: group.id, roles: %i[guest reporter developer maintainer] }]
      }
    })
  end
end
