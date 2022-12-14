# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting ancestors of an epic', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:parent_group) { create(:group, :private) }
  let_it_be(:group) { create(:group, :private, parent: parent_group) }
  let_it_be(:ancestor_a) { create(:epic, group: parent_group) }
  let_it_be(:ancestor_b) { create(:epic, group: group, parent: ancestor_a) }
  let_it_be(:epic) { create(:epic, group: group, parent: ancestor_b) }

  let(:epics_data) { graphql_data['group']['epics']['edges'] }

  let(:epic_node) do
    <<~NODE
      edges {
        node {
          id
          iid
          ancestors {
            edges {
              node {
                iid
              }
            }
          }
        }
      }
    NODE
  end

  def query(params = {})
    graphql_query_for(
      "group", { "fullPath" => group.full_path },
      ['epicsEnabled', query_graphql_field("epics", params, epic_node)]
    )
  end

  def epic_node_array(extract_attribute = nil)
    node_array(epics_data, extract_attribute)
  end

  context 'when epics are enabled' do
    before do
      stub_licensed_features(epics: true)
      group.add_developer(user)
    end

    it 'finds ancestors from group' do
      post_graphql(query(iid: epic.iid), current_user: user)

      expect(epic_node_array('ancestors'))
        .to include({ 'edges' => [{ 'node' => { 'iid' => ancestor_b.iid.to_s } }] })
    end

    context 'when user has access to the parent group epics' do
      before do
        parent_group.add_developer(user)
      end

      it 'finds ancestors from group and parent group' do
        post_graphql(query(iid: epic.iid), current_user: user)

        expect(epic_node_array('ancestors')).to include(
          { 'edges' =>
            [{ 'node' => { 'iid' => ancestor_b.iid.to_s } },
             { 'node' => { 'iid' => ancestor_a.iid.to_s } }] }
        )
      end
    end
  end

  context 'when epics are disabled' do
    before do
      group.add_developer(user)
      stub_licensed_features(epics: false)
    end

    it 'does not find the epic ancestors' do
      post_graphql(query(iid: epic.iid), current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to be_nil
      expect(epic_node_array('ancestors')).to be_empty
    end
  end
end
