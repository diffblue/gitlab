# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a work item', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:developer) { create(:user).tap { |user| project.add_developer(user) } }

  let(:mutation) { graphql_mutation(:workItemCreate, input.merge('projectPath' => project.full_path)) }
  let(:mutation_response) { graphql_mutation_response(:work_item_create) }

  context 'when user has permissions to create a work item' do
    let(:current_user) { developer }

    context 'with iteration widget input' do
      let(:widgets_response) { mutation_response['workItem']['widgets'] }
      let(:fields) do
        <<~FIELDS
        workItem {
          widgets {
            type
            ... on WorkItemWidgetIteration {
              iteration {
                id
              }
            }
          }
        }
        errors
        FIELDS
      end

      let(:mutation) { graphql_mutation(:workItemCreate, input.merge('projectPath' => project.full_path), fields) }

      context 'when setting iteration on work item creation' do
        let_it_be(:cadence) { create(:iterations_cadence, group: group) }
        let_it_be(:iteration) { create(:iteration, iterations_cadence: cadence) }

        let(:input) do
          {
            title: 'new title',
            workItemTypeId: WorkItems::Type.default_by_type(:task).to_global_id.to_s,
            iterationWidget: { 'iterationId' => iteration.to_global_id.to_s }
          }
        end

        before do
          stub_licensed_features(iterations: true)
        end

        it "sets the work item's iteration", :aggregate_failures do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.to change { WorkItem.count }.by(1)

          expect(response).to have_gitlab_http_status(:success)
          expect(widgets_response).to include(
            {
              'type' => 'ITERATION',
              'iteration' => { 'id' => iteration.to_global_id.to_s }
            }
          )
        end

        context 'when iterations feature is unavailable' do
          before do
            stub_licensed_features(iterations: false)
          end

          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/383322
          # We prefer to return an error rather than nil when authorization for an object fails.
          # Here the authorization fails due to the unavailability of the licensed feature.
          # Because the object to be authorized gets loaded via argument inside an InputObject,
          # we need to add an additional hook to Types::BaseInputObject so errors are raised.
          it 'returns nil' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
            end.to change { WorkItem.count }.by(0)

            expect(mutation_response).to be_nil
          end
        end
      end
    end
  end
end
