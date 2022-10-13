# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update a work item' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:reporter) { create(:user).tap { |user| project.add_reporter(user) } }
  let_it_be(:guest) { create(:user).tap { |user| project.add_guest(user) } }
  let_it_be(:work_item, refind: true) { create(:work_item, project: project) }

  let(:mutation) { graphql_mutation(:workItemUpdate, input.merge('id' => work_item.to_global_id.to_s), fields) }

  let(:mutation_response) { graphql_mutation_response(:work_item_update) }

  shared_examples 'work item is not updated' do
    it 'ignores the update' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { work_item.reload }
    end
  end

  shared_examples 'user without permission to admin work item cannot update the attribute' do
    # A guest user who is also the author of a work item can update some of its attrs (policy :update_work_item.)
    # Only a reporter (or above) may update the weight (policy :admin_work_item.)
    context 'when a guest user is also an author of the work item' do
      let(:current_user) { guest }

      let_it_be(:work_item) { create(:work_item, project: project, author: guest) }

      it_behaves_like 'work item is not updated'
    end
  end

  context 'with iteration widget input' do
    let_it_be(:cadence) { create(:iterations_cadence, group: group) }
    let_it_be(:old_iteration) { create(:iteration, iterations_cadence: cadence) }
    let_it_be(:new_iteration) { create(:iteration, iterations_cadence: cadence) }

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

    let(:iteration_id) { new_iteration.to_global_id.to_s }
    let(:input) { { 'iterationWidget' => { 'iterationId' => iteration_id } } }

    before do
      work_item.update!(iteration: old_iteration)
    end

    context 'when iterations feature is unlicensed' do
      let(:current_user) { reporter }

      before do
        stub_licensed_features(iterations: false)
      end

      it_behaves_like 'work item is not updated'
    end

    context 'when iterations feature is licensed' do
      before do
        stub_licensed_features(iterations: true)
      end

      it_behaves_like 'user without permission to admin work item cannot update the attribute'

      context 'when user has permissions to admin a work item' do
        let(:current_user) { reporter }

        shared_examples "work item's iteration is updated" do
          it "updates the work item's iteration" do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)

              work_item.reload
            end.to change(work_item, :iteration).from(old_iteration).to(new_iteration)

            expect(response).to have_gitlab_http_status(:success)
          end
        end

        context 'when setting to a new iteration' do
          it_behaves_like "work item's iteration is updated"
        end

        context 'when setting iteration to null' do
          let(:new_iteration) { nil }
          let(:iteration_id) { nil }

          it_behaves_like "work item's iteration is updated"
        end
      end

      context 'when the user does not have permission to update the work item' do
        let(:current_user) { guest }

        it_behaves_like 'a mutation that returns top-level errors', errors: [
          'The resource that you are attempting to access does not exist or you don\'t have permission to ' \
          'perform this action'
        ]

        it_behaves_like 'work item is not updated'
      end
    end
  end

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

      it_behaves_like 'work item is not updated'
    end

    context 'when issuable weights is licensed' do
      before do
        stub_licensed_features(issue_weights: true)
      end

      context 'when user has permissions to admin a work item' do
        let(:current_user) { reporter }

        it_behaves_like 'update work item weight widget'

        context 'when setting weight to null' do
          let(:input) do
            { 'weightWidget' => { 'weight' => nil } }
          end

          before do
            work_item.update!(weight: 2)
          end

          it 'updates the work item' do
            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.to change(work_item, :weight).from(2).to(nil)

            expect(response).to have_gitlab_http_status(:success)
          end
        end
      end

      it_behaves_like 'user without permission to admin work item cannot update the attribute'

      context 'when the user does not have permission to update the work item' do
        let(:current_user) { guest }

        it_behaves_like 'a mutation that returns top-level errors', errors: [
          'The resource that you are attempting to access does not exist or you don\'t have permission to ' \
          'perform this action'
        ]

        it_behaves_like 'work item is not updated'
      end
    end
  end

  context 'with status widget input' do
    let(:new_status) { 'FAILED' }
    let(:input) { { 'statusWidget' => { 'status' => new_status } } }

    let_it_be_with_refind(:work_item) { create(:work_item, :satisfied_status, project: project) }

    let(:fields) do
      <<~FIELDS
        workItem {
          widgets {
            type
            ... on WorkItemWidgetStatus {
              status
            }
          }
        }
        errors
      FIELDS
    end

    def work_item_status
      state = work_item.requirement&.last_test_report_state
      ::WorkItems::Widgets::Status::STATUS_MAP[state]
    end

    context 'when requirements is unlicensed' do
      let(:current_user) { reporter }

      before do
        stub_licensed_features(requirements: false)
      end

      it_behaves_like 'work item is not updated'
    end

    context 'when requirements is licensed' do
      before do
        stub_licensed_features(requirements: true)
      end

      context 'when user has permissions to admin a work item' do
        let(:current_user) { reporter }

        it_behaves_like 'update work item status widget'

        context 'when setting status to an invalid value' do
          # while a requirement can have a status 'unverified'
          # it can't be directly set that way

          let(:input) do
            { 'statusWidget' => { 'status' => 'UNVERIFIED' } }
          end

          it "does not update the work item's status" do
            # due to 'passed' internally and 'satisfied' externally, map it here
            expect(work_item_status).to eq("satisfied")

            expect do
              post_graphql_mutation(mutation, current_user: current_user)
              work_item.reload
            end.not_to change { work_item_status }

            expect(work_item_status).to eq("satisfied")
          end
        end
      end

      it_behaves_like 'user without permission to admin work item cannot update the attribute'

      context 'when the user does not have permission to update the work item' do
        let(:current_user) { guest }

        it_behaves_like 'a mutation that returns top-level errors', errors: [
          'The resource that you are attempting to access does not exist or you don\'t have permission to ' \
          'perform this action'
        ]

        it_behaves_like 'work item is not updated'
      end
    end
  end
end
