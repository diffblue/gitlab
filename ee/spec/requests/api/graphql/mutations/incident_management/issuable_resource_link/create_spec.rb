# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating an issuable resource link', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:link_text) { 'Incident zoom link' }

  let(:link) { 'https://gitlab.zoom.us/incident_link' }
  let(:link_type) { :zoom }
  let(:input) { { id: incident.to_global_id.to_s, link: link, link_text: link_text, link_type: link_type } }
  let(:mutation) do
    graphql_mutation(:issuable_resource_link_create, input) do
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

  let(:mutation_response) { graphql_mutation_response(:issuable_resource_link_create) }

  before do
    stub_licensed_features(issuable_resource_links: true)
    project.add_reporter(user)
  end

  it 'creates issuable resource link', :aggregate_failures do
    post_graphql_mutation(mutation, current_user: user)

    issuable_resource_link = mutation_response['issuableResourceLink']

    expect(response).to have_gitlab_http_status(:success)
    expect(issuable_resource_link).to include(
      'issue' => {
        'id' => incident.to_global_id.to_s,
        'title' => incident.title
      },
      'link' => link,
      'linkType' => link_type.to_s,
      'linkText' => link_text
    )
  end

  context 'returns error' do
    context 'when link is invalid' do
      let(:link) { 'ftp://file_service.link' }

      it 'returns nil' do
        post_graphql_mutation(mutation, current_user: user)

        issuable_resource_link = mutation_response['issuableResourceLink']

        expect(issuable_resource_link).to be_nil
        expect(mutation_response['errors']).to contain_exactly('Link is blocked: Only allowed schemes are http, https')
      end
    end
  end
end
