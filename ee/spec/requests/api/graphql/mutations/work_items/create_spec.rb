# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a work item', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:developer) { create(:user).tap { |user| group.add_developer(user) } }

  let(:mutation_response) { graphql_mutation_response(:work_item_create) }
  let(:widgets_response) { mutation_response['workItem']['widgets'] }

  RSpec.shared_examples 'creates work item' do
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

    context 'when creating a key result' do
      let_it_be(:parent) { create(:work_item, :objective, **container_params) }

      let(:fields) do
        <<~FIELDS
          workItem {
            id
            workItemType {
              id
            }
            widgets {
              type
              ... on WorkItemWidgetHierarchy {
                parent {
                  id
                }
              }
            }
          }
          errors
        FIELDS
      end

      let(:input) do
        {
          title: 'key result',
          workItemTypeId: WorkItems::Type.default_by_type(:key_result).to_global_id.to_s,
          hierarchyWidget: { 'parentId' => parent.to_global_id.to_s }
        }
      end

      let(:widgets_response) { mutation_response['workItem']['widgets'] }

      context 'when okrs are available' do
        before do
          stub_licensed_features(okrs: true)
        end

        it 'creates the work item' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.to change { WorkItem.count }.by(1)

          expect(response).to have_gitlab_http_status(:success)
          expect(widgets_response).to include(
            {
              'parent' => { 'id' => parent.to_global_id.to_s },
              'type' => 'HIERARCHY'
            }
          )
        end
      end

      context 'when okrs are not available' do
        before do
          stub_licensed_features(okrs: false)
        end

        it 'returns error' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
          end.to not_change(WorkItem, :count)

          expect(mutation_response['errors'])
            .to contain_exactly(/cannot be added: is not allowed to add this type of parent/)
          expect(mutation_response['workItem']).to be_nil
        end
      end
    end
  end

  context 'when user has permissions to create a work item' do
    let(:current_user) { developer }

    context 'with iteration widget input' do
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

      context 'when creating work items in a project' do
        context 'with projectPath' do
          let_it_be(:container_params) { { project: project } }
          let(:mutation) { graphql_mutation(:workItemCreate, input.merge(projectPath: project.full_path), fields) }

          it_behaves_like 'creates work item'
        end

        context 'with namespacePath' do
          let_it_be(:container_params) { { project: project } }
          let(:mutation) { graphql_mutation(:workItemCreate, input.merge(namespacePath: project.full_path), fields) }

          it_behaves_like 'creates work item'
        end
      end

      context 'when creating work items in a group' do
        let_it_be(:container_params) { { namespace: group } }
        let(:mutation) { graphql_mutation(:workItemCreate, input.merge(namespacePath: group.full_path), fields) }

        it_behaves_like 'creates work item'
      end
    end
  end
end
