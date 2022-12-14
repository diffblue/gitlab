# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting issuable resource links', feature_category: :incident_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:incident) { create(:incident, project: project) }
  let_it_be(:issuable_resource_link_1) { create(:issuable_resource_link, issue: incident) }
  let_it_be(:issuable_resource_link_2) { create(:issuable_resource_link, issue: incident) }

  let(:params) { { incident_id: incident.to_global_id.to_s } }

  let(:issuable_resource_link_fields) do
    <<~QUERY
      nodes {
        id
        issue { id title }
        link
        linkType
        linkText
      }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'issue',
      { 'id' => global_id_of(incident) },
      query_graphql_field('issuableResourceLinks', params, issuable_resource_link_fields)
    )
  end

  let(:issuable_resource_links) do
    graphql_data.dig('issue', 'issuableResourceLinks', 'nodes')
  end

  context 'when feature is available' do
    before do
      stub_licensed_features(issuable_resource_links: true)
      project.add_reporter(current_user)
      post_graphql(query, current_user: current_user)
    end

    context 'when user has permissions' do
      it_behaves_like 'a working graphql query'

      it 'returns the correct number of resource links' do
        expect(issuable_resource_links.count).to eq(2)
      end

      it 'returns the correct properties of the resource links' do
        expect(issuable_resource_links.first).to include(
          'id' => issuable_resource_link_1.to_global_id.to_s,
          'issue' => {
            'id' => incident.to_global_id.to_s,
            'title' => incident.title
          },
          'link' => issuable_resource_link_1.link,
          'linkType' => issuable_resource_link_1.link_type.to_s,
          'linkText' => issuable_resource_link_1.link_text
        )
      end
    end

    context 'when user does not have permission' do
      before do
        project.add_guest(current_user)
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      it 'returns empty results' do
        expect(issuable_resource_links).to be_empty
      end
    end
  end

  context 'when feature is unavailable' do
    before do
      stub_licensed_features(issuable_resource_links: false)
      project.add_reporter(current_user)
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns empty results' do
      expect(issuable_resource_links).to be_empty
    end
  end
end
