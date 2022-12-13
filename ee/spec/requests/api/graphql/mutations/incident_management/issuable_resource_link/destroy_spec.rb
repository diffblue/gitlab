# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Removing an issuable resource link', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:issuable_resource_link) { create(:issuable_resource_link, issue: incident) }

  let(:variables) { { id: issuable_resource_link.to_global_id.to_s } }

  let(:mutation) do
    graphql_mutation(:issuable_resource_link_destroy, variables) do
      <<~QL
        clientMutationId
        errors
        issuableResourceLink {
          id
          issue { id title }
          link
          linkText
          linkType
        }
      QL
    end
  end

  let(:mutation_response) { graphql_mutation_response(:issuable_resource_link_destroy) }

  before do
    stub_licensed_features(issuable_resource_links: true)
    project.add_reporter(user)
  end

  it 'removes the issuable resource link', :aggregate_failures do
    post_graphql_mutation(mutation, current_user: user)

    issuable_resource_link_response = mutation_response['issuableResourceLink']

    expect(response).to have_gitlab_http_status(:success)
    expect(issuable_resource_link_response).to include(
      'issue' => {
        'id' => incident.to_global_id.to_s,
        'title' => incident.title
      },
      'link' => issuable_resource_link.link,
      'linkType' => issuable_resource_link.link_type.to_s,
      'linkText' => issuable_resource_link.link_text
    )
    expect { issuable_resource_link.reload }.to raise_error ActiveRecord::RecordNotFound
  end
end
