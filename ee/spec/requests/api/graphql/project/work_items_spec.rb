# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a work item list for a project' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:current_user) { create(:user) }

  let(:items_data) { graphql_data['project']['workItems']['edges'] }
  let(:item_ids) { graphql_dig_at(items_data, :node, :id) }
  let(:item_filter_params) { {} }

  let(:fields) do
    <<~QUERY
    edges {
      node {
        #{all_graphql_fields_for('workItems'.classify)}
      }
    }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('workItems', item_filter_params, fields)
    )
  end

  describe 'work items with widgets' do
    let(:widgets_data) { graphql_dig_at(items_data, :node, :widgets) }

    context 'with verification status widget' do
      let_it_be(:work_item1) { create(:work_item, :satisfied_status, project: project) }
      let_it_be(:work_item2) { create(:work_item, :failed_status, project: project) }
      let_it_be(:work_item3) { create(:work_item, :requirement, project: project) }

      let(:fields) do
        <<~QUERY
        edges {
          node {
            id
            widgets {
              type
              ... on WorkItemWidgetVerificationStatus {
                verificationStatus
              }
            }
          }
        }
        QUERY
      end

      before do
        stub_licensed_features(requirements: true)
      end

      it 'returns work items including verification status', :aggregate_failures do
        post_graphql(query, current_user: current_user)

        expect(item_ids).to contain_exactly(
          work_item1.to_global_id.to_s,
          work_item2.to_global_id.to_s,
          work_item3.to_global_id.to_s
        )
        expect(widgets_data).to include(
          a_hash_including('verificationStatus' => 'satisfied'),
          a_hash_including('verificationStatus' => 'failed'),
          a_hash_including('verificationStatus' => 'unverified')
        )
      end

      it 'avoids N+1 queries' do
        post_graphql(query, current_user: current_user) # warm-up

        control = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: current_user)
        end

        create_list(:work_item, 3, :satisfied_status, project: project)

        expect { post_graphql(query, current_user: current_user) }.not_to exceed_query_limit(control)
      end
    end
  end
end
