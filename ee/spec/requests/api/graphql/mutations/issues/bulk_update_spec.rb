# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Bulk update issues', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:group) { create(:group).tap { |group| group.add_developer(developer) } }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:updatable_issues, reload: true) { create_list(:issue, 2, project: project) }
  let_it_be(:iteration) { create(:iteration, group: group) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:health_status) { Issue.health_statuses.keys[0] }

  let(:parent) { project }
  let(:mutation) { graphql_mutation(:issues_bulk_update, base_arguments.merge(additional_arguments)) }
  let(:mutation_response) { graphql_mutation_response(:issues_bulk_update) }
  let(:current_user) { developer }
  let(:base_arguments) { { parent_id: parent.to_gid.to_s, ids: updatable_issues.map { |i| i.to_gid.to_s } } }

  let(:additional_arguments) do
    {
      iteration_id: iteration.to_gid.to_s,
      epic_id: epic.to_gid.to_s,
      health_status: health_status.camelize(:lower).to_sym
    }
  end

  before do
    stub_licensed_features(epics: true, issuable_health_status: true)
  end

  context 'when user can update all issues' do
    it 'updates all issues' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        updatable_issues.each(&:reload)
      end.to change { updatable_issues.map(&:sprint_id) }.from([nil] * 2).to([iteration.id] * 2)
        .and(change { updatable_issues.map { |i| i.epic&.id } }.from([nil] * 2).to([epic.id] * 2))
        .and(change { updatable_issues.map(&:health_status) }.from([nil] * 2).to([health_status] * 2))

      expect(mutation_response).to include(
        'updatedIssueCount' => updatable_issues.count
      )
    end

    context 'when setting arguments to null or none' do
      let(:additional_arguments) { { iteration_id: nil, epic_id: nil, health_status: nil } }

      before do
        updatable_issues.each do |issue|
          issue.update!(iteration: iteration, epic: epic, health_status: health_status)
        end
      end

      it 'updates all issues' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          updatable_issues.each(&:reload)
        end.to change { updatable_issues.map(&:sprint_id) }.from([iteration.id] * 2).to([nil] * 2)
          .and(change { updatable_issues.map { |i| i.epic&.id } }.from([epic.id] * 2).to([nil] * 2))
          .and(change { updatable_issues.map(&:health_status) }.from([health_status] * 2).to([nil] * 2))

        expect(mutation_response).to include(
          'updatedIssueCount' => updatable_issues.count
        )
      end
    end

    context 'when scoping to a parent group' do
      let(:parent) { group }

      context 'when group_bulk_edit feature is available' do
        before do
          stub_licensed_features(group_bulk_edit: true, epics: true, issuable_health_status: true)
        end

        it 'updates all issues' do
          expect do
            post_graphql_mutation(mutation, current_user: current_user)
            updatable_issues.each(&:reload)
          end.to change { updatable_issues.map(&:sprint_id) }.from([nil] * 2).to([iteration.id] * 2)
            .and(change { updatable_issues.map { |i| i.epic&.id } }.from([nil] * 2).to([epic.id] * 2))
            .and(change { updatable_issues.map(&:health_status) }.from([nil] * 2).to([health_status] * 2))

          expect(mutation_response).to include(
            'updatedIssueCount' => updatable_issues.count
          )
        end

        context 'when current user cannot read the specified group' do
          let(:parent) { create(:group, :private) }

          it 'returns a resource not found error' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(graphql_errors).to contain_exactly(
              hash_including(
                'message' => "The resource that you are attempting to access does not exist or you don't have " \
                             'permission to perform this action'
              )
            )
          end
        end
      end

      context 'when group_bulk_edit feature is not available' do
        before do
          stub_licensed_features(group_bulk_edit: false)
        end

        it 'returns a resource not available message' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(graphql_errors).to contain_exactly(
            hash_including(
              'message' => "The resource that you are attempting to access does not exist or you don't have " \
                           'permission to perform this action'
            )
          )
        end
      end
    end
  end
end
