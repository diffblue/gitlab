# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting children of an epic', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:ancestor) { create(:group, :private) }
  let_it_be(:group) { create(:group, :private, parent: ancestor) }
  let_it_be(:descendant) { create(:group, :private, parent: group) }
  let_it_be(:other_group) { create(:group, :private) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:group_child) { create(:epic, group: group, parent: epic) }
  let_it_be(:other_group_child) { create(:epic, group: other_group, parent: epic) }
  let_it_be(:ancestor_group_child) { create(:epic, group: ancestor, parent: epic) }
  let_it_be(:descendant_group_child) { create(:epic, group: descendant, parent: epic) }

  let(:epics_data) { graphql_data['group']['epics']['edges'] }

  def query(params: {}, children_params: {})
    graphql_query_for(
      "group", { "fullPath" => group.full_path },
      ['epicsEnabled', query_graphql_field("epics", params, epic_node(children_params))]
    )
  end

  def epic_node(params = {})
    include_ancestors = params.fetch(:include_ancestor_groups, true)
    include_descendants = params.fetch(:include_descendant_groups, true)

    <<~NODE
      edges {
        node {
          id
          iid
          children(includeAncestorGroups: #{include_ancestors}, includeDescendantGroups: #{include_descendants}) {
            edges {
              node {
                id
              }
            }
          }
        }
      }
    NODE
  end

  def epic_node_array(extract_attribute = nil)
    node_array(epics_data, extract_attribute)
  end

  context 'when epics are enabled' do
    before do
      stub_licensed_features(epics: true, subepics: true)
      group.add_reporter(user)
    end

    subject(:run_query) { post_graphql(query(params: { iid: epic.iid }), current_user: user) }

    it 'returns children from authorized groups' do
      run_query

      expect(epic_node_array('children'))
        .to include({ 'edges' =>
          [{ 'node' => { 'id' => descendant_group_child.to_gid.to_s } },
           { 'node' => { 'id' => group_child.to_gid.to_s } }] })
    end

    context 'when user has access to all children groups' do
      before do
        ancestor.add_reporter(user)
        descendant.add_reporter(user)
        other_group.add_reporter(user)
      end

      it 'returns all children' do
        run_query

        expect(epic_node_array('children')).to include(
          { 'edges' =>
            [{ 'node' => { 'id' => descendant_group_child.to_gid.to_s } },
             { 'node' => { 'id' => ancestor_group_child.to_gid.to_s } },
             { 'node' => { 'id' => other_group_child.to_gid.to_s } },
             { 'node' => { 'id' => group_child.to_gid.to_s } }] })
      end

      context 'when include_ancestor_groups is `false`' do
        it 'excludes children from ancestor groups' do
          post_graphql(
            query(params: { iid: epic.iid }, children_params: { include_ancestor_groups: false }),
            current_user: user
          )

          expect(epic_node_array('children')).to include(
            { 'edges' =>
              [{ 'node' => { 'id' => descendant_group_child.to_gid.to_s } },
               { 'node' => { 'id' => other_group_child.to_gid.to_s } },
               { 'node' => { 'id' => group_child.to_gid.to_s } }] })
        end
      end

      context 'when include_descendant_groups is `false`' do
        it 'excludes children from descendant groups' do
          post_graphql(
            query(params: { iid: epic.iid }, children_params: { include_descendant_groups: false }),
            current_user: user)

          expect(epic_node_array('children')).to include(
            { 'edges' =>
             [{ 'node' => { 'id' => ancestor_group_child.to_gid.to_s } },
              { 'node' => { 'id' => other_group_child.to_gid.to_s } },
              { 'node' => { 'id' => group_child.to_gid.to_s } }] })
        end
      end

      context 'when include_descendant_groups and include_ancestor_groups are `false`' do
        it 'excludes children from descendant and ancestor groups' do
          post_graphql(
            query(params: { iid: epic.iid },
                  children_params: { include_descendant_groups: false, include_ancestor_groups: false }),
            current_user: user)

          expect(epic_node_array('children')).to include(
            { 'edges' =>
             [{ 'node' => { 'id' => other_group_child.to_gid.to_s } },
              { 'node' => { 'id' => group_child.to_gid.to_s } }] })
        end
      end

      it 'executes limited number of N+1 queries' do
        # An additional `SELECT "saml_providers".* FROM "saml_providers"...` query
        # per group outside the hierarchy
        extra_queries = 2

        def run_query
          post_graphql(query(params: { iid: epic.iid }), current_user: user)
        end

        run_query # warm-up

        control_count = ActiveRecord::QueryRecorder.new do
          post_graphql(query(params: { iid: epic.iid }), current_user: user)
        end

        create(:epic, group: ancestor, parent: epic)
        create(:epic, group: descendant, parent: epic)
        create(:epic, parent: epic)
        create(:epic, parent: epic)

        expect do
          post_graphql(query(params: { iid: epic.iid }), current_user: user)
        end.not_to exceed_query_limit(control_count).with_threshold(extra_queries)
        expect(graphql_errors).to be_nil
      end
    end
  end

  context 'when epics are disabled' do
    before do
      group.add_developer(user)
      stub_licensed_features(epics: false)
    end

    it 'does not find the epic children' do
      post_graphql(query(params: { iid: epic.iid }), current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to be_nil
      expect(epic_node_array('children')).to be_empty
    end
  end
end
