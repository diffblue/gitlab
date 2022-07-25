# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.work_item(id)' do
  include GraphqlHelpers

  let_it_be(:guest) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:work_item) { create(:work_item, project: project, description: '- List item', weight: 1) }

  let(:current_user) { guest }
  let(:work_item_data) { graphql_data['workItem'] }
  let(:work_item_fields) { all_graphql_fields_for('WorkItem') }
  let(:global_id) { work_item.to_gid.to_s }

  let(:query) do
    graphql_query_for('workItem', { 'id' => global_id }, work_item_fields)
  end

  context 'when the user can read the work item' do
    before do
      project.add_guest(guest)
    end

    context 'when querying widgets' do
      describe 'weight widget' do
        let(:work_item_fields) do
          <<~GRAPHQL
            id
            widgets {
              type
              ... on WorkItemWidgetWeight {
                weight
              }
            }
          GRAPHQL
        end

        context 'when issuable weights is licensed' do
          before do
            stub_licensed_features(issue_weights: true)

            post_graphql(query, current_user: current_user)
          end

          it 'returns widget information' do
            expect(work_item_data).to include(
              'id' => work_item.to_gid.to_s,
              'widgets' => include(
                hash_including(
                  'type' => 'WEIGHT',
                  'weight' => work_item.weight
                )
              )
            )
          end
        end

        context 'when issuable weights is unlicensed' do
          before do
            stub_licensed_features(issue_weights: false)

            post_graphql(query, current_user: current_user)
          end

          it 'returns without weight' do
            expect(work_item_data).not_to include(
              'widgets' => include(
                hash_including(
                  'type' => 'WEIGHT',
                  'weight' => work_item.weight
                )
              )
            )
          end
        end
      end
    end
  end
end
