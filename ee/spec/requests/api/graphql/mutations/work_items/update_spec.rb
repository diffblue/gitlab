# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update a work item' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:reporter) { create(:user).tap { |user| project.add_reporter(user) } }
  let_it_be(:guest) { create(:user).tap { |user| project.add_guest(user) } }
  let_it_be(:work_item, refind: true) { create(:work_item, project: project) }

  let(:mutation) { graphql_mutation(:workItemUpdate, input.merge('id' => work_item.to_global_id.to_s), fields) }

  let(:mutation_response) { graphql_mutation_response(:work_item_update) }

  context 'with weight widget input' do
    let(:new_weight) { 2 }
    let(:input) { { 'weightWidget' => { 'weight' => new_weight } } }

    let(:fields) do
      <<~FIELDS
        workItem {
          widgets {
            type
            ... on WorkItemWidgetWeight {
              weight
            }
          }
        }
        errors
      FIELDS
    end

    context 'when issuable weights is unlicensed' do
      let(:current_user) { reporter }

      before do
        stub_licensed_features(issue_weights: false)
      end

      it 'ignores the update' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.not_to change { work_item.reload }
      end
    end

    context 'when issuable weights is licensed' do
      before do
        stub_licensed_features(issue_weights: true)
      end

      context 'when user has permissions to admin a work item' do
        let(:current_user) { reporter }

        it_behaves_like 'update work item weight widget'
      end

      context 'when user has permissions to update a work item' do
        let(:current_user) { guest }

        let_it_be(:work_item) { create(:work_item, project: project, author: guest) }

        # A guest user who is also the author of a work item can update some of its attrs (policy :update_work_item.)
        # Only a reporter (or above) may update the weight (policy :admin_work_item.)
        it 'ignores the update' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.not_to change { work_item.reload }
        end
      end

      context 'when the user does not have permission to update the work item' do
        let(:current_user) { guest }

        it 'returns an error if the user is not allowed to update the work item' do
          error = "The resource that you are attempting to access does not exist or you "\
                  "don't have permission to perform this action"

          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.not_to change { work_item.reload }

          expect(graphql_errors).to include(a_hash_including('message' => error))
        end
      end
    end
  end
end
