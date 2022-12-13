# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a work item list for a project', feature_category: :team_planning do
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

    context 'with status widget' do
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
              ... on WorkItemWidgetStatus {
                status
              }
            }
          }
        }
        QUERY
      end

      before do
        stub_licensed_features(requirements: true, okrs: true)
      end

      it 'returns work items including status', :aggregate_failures do
        post_graphql(query, current_user: current_user)

        expect(item_ids).to contain_exactly(
          work_item1.to_global_id.to_s,
          work_item2.to_global_id.to_s,
          work_item3.to_global_id.to_s
        )
        expect(widgets_data).to include(
          a_hash_including('status' => 'satisfied'),
          a_hash_including('status' => 'failed'),
          a_hash_including('status' => 'unverified')
        )
      end

      it 'avoids N+1 queries', :use_sql_query_cache do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: current_user)
        end

        create_list(:work_item, 3, :satisfied_status, project: project)

        expect { post_graphql(query, current_user: current_user) }.not_to exceed_all_query_limit(control)
      end

      context 'when filtering' do
        context 'with status widget' do
          let(:item_filter_params) { 'statusWidget: { status: FAILED }' }

          it 'filters by status argument' do
            post_graphql(query, current_user: current_user)

            expect(response).to have_gitlab_http_status(:success)
            expect(item_ids).to contain_exactly(work_item2.to_global_id.to_s)
          end
        end
      end
    end

    describe 'fetching work item notes widget' do
      let(:work_item) { create(:work_item, project: project) }
      let(:item_filter_params) { { iid: work_item.iid.to_s } }
      let(:fields) do
        <<~GRAPHQL
        edges {
          node {
            widgets {
              type
              ... on WorkItemWidgetNotes {
                system: discussions(filter: ONLY_ACTIVITY, first: 10) { nodes { id  notes { nodes { id system internal body } } } },
                comments: discussions(filter: ONLY_COMMENTS, first: 10) { nodes { id  notes { nodes { id system internal body } } } },
                all_notes: discussions(filter: ALL_NOTES, first: 10) { nodes { id  notes { nodes { id system internal body } } } }
              }
            }
          }
        }
        GRAPHQL
      end

      it 'fetches notes that require gitaly call to parse note' do
        # this 9 digit long weight triggers a gitaly call when parsing the system note
        create(:resource_weight_event, user: current_user, issue: work_item, weight: 123456789)

        post_graphql(query, current_user: current_user)

        expect_graphql_errors_to_be_empty
      end
    end

    context 'with progress widget' do
      let_it_be(:work_item1) { create(:work_item, :objective, project: project) }
      let_it_be(:progress) { create(:progress, work_item: work_item1) }

      let(:fields) do
        <<~QUERY
        edges {
          node {
            id
            widgets {
              type
              ... on WorkItemWidgetProgress {
                progress
              }
            }
          }
        }
        QUERY
      end

      before do
        stub_licensed_features(okrs: true)
      end

      it 'avoids N+1 queries', :use_sql_query_cache do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          post_graphql(query, current_user: current_user)
        end

        create_list(:work_item, 3, :objective, project: project)

        expect { post_graphql(query, current_user: current_user) }.not_to exceed_all_query_limit(control)
      end
    end
  end
end
