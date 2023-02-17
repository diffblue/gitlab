# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Bulk update issues', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:group) { create(:group).tap { |group| group.add_developer(developer) } }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:updatable_issues, reload: true) { create_list(:issue, 2, project: project) }
  let_it_be(:iteration) { create(:iteration, group: group) }

  let(:parent) { project }
  let(:mutation) { graphql_mutation(:issues_bulk_update, base_arguments.merge(additional_arguments)) }
  let(:mutation_response) { graphql_mutation_response(:issues_bulk_update) }
  let(:current_user) { developer }
  let(:base_arguments) { { parent_id: parent.to_gid.to_s, ids: updatable_issues.map { |i| i.to_gid.to_s } } }

  let(:additional_arguments) do
    {
      iteration_id: iteration.to_gid.to_s
    }
  end

  context 'when user can update all issues' do
    it 'updates all issues' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
        updatable_issues.each(&:reload)
      end.to change { updatable_issues.map(&:sprint_id) }.from([nil] * 2).to([iteration.id] * 2)

      expect(mutation_response).to include(
        'updatedIssueCount' => updatable_issues.count
      )
    end

    context 'when setting arguments to null or none' do
      let(:additional_arguments) { { iteration_id: nil } }

      before do
        updatable_issues.each do |issue|
          issue.update!(iteration: iteration)
        end
      end

      it 'updates all issues' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
          updatable_issues.each(&:reload)
        end.to change { updatable_issues.map(&:sprint_id) }.from([iteration.id] * 2).to([nil] * 2)

        expect(mutation_response).to include(
          'updatedIssueCount' => updatable_issues.count
        )
      end
    end
  end
end
