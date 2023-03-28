# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting the compliance violations for a group', feature_category: :compliance_management do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:project2) { create(:project, :repository, group: group) }
  let_it_be(:project_outside_group) { create(:project, :repository, group: create(:group)) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project, state: :merged, title: 'abcd') }
  let_it_be(:merge_request2) { create(:merge_request, source_project: project2, target_project: project2, state: :merged, title: 'zyxw') }
  let_it_be(:merge_request_outside_group) { create(:merge_request, source_project: project_outside_group, target_project: project_outside_group, state: :merged) }

  let_it_be(:compliance_violation) do
    create(:compliance_violation, :approved_by_committer, severity_level: :low, merge_request: merge_request,
      title: 'abcd', target_project_id: project.id, target_branch: merge_request.target_branch, merged_at: 3.days.ago)
  end

  let_it_be(:compliance_violation2) do
    create(:compliance_violation, :approved_by_merge_request_author, severity_level: :high,
      merge_request: merge_request2, title: 'zyxw', target_project_id: project2.id,
      target_branch: merge_request2.target_branch, merged_at: 1.day.ago)
  end

  let_it_be(:compliance_violation_outside_group) do
    create(:compliance_violation, :approved_by_committer, merge_request: merge_request_outside_group,
      title: merge_request_outside_group, target_project_id: project_outside_group.id,
      target_branch: merge_request_outside_group.target_branch)
  end

  let(:fields) do
    <<~GRAPHQL
      nodes {
        id
        severityLevel
        reason
        violatingUser {
          id
        }
        mergeRequest {
          id
        }
      }
    GRAPHQL
  end

  def get_violation_values(violation)
    {
      'id' => violation.to_global_id.to_s,
      'severityLevel' => ::Types::ComplianceManagement::MergeRequests::ComplianceViolationSeverityEnum.values[violation.severity_level.upcase].graphql_name,
      'reason' => ::Types::ComplianceManagement::MergeRequests::ComplianceViolationReasonEnum.values[violation.reason.underscore.upcase].graphql_name,
      'violatingUser' => {
        'id' => violation.violating_user.to_global_id.to_s
      },
      'mergeRequest' => {
        'id' => violation.merge_request.to_global_id.to_s
      }
    }
  end

  let(:violation_output) do
    get_violation_values(compliance_violation)
  end

  let(:violation2_output) do
    get_violation_values(compliance_violation2)
  end

  def query(params = {})
    graphql_query_for(
      :group, { full_path: group.full_path }, query_graphql_field("mergeRequestViolations", params, fields)
    )
  end

  let(:compliance_violations) { graphql_data_at(:group, :merge_request_violations, :nodes) }

  before do
    merge_request.metrics.update!(merged_at: 3.days.ago)
    merge_request2.metrics.update!(merged_at: 1.day.ago)
  end

  context 'when the user is unauthorized' do
    it 'returns nil' do
      post_graphql(query, current_user: current_user)

      expect(compliance_violations).to be_nil
    end
  end

  context 'when the user is authorized' do
    before do
      group.add_owner(current_user)
    end

    context 'without any filters or sorting' do
      it 'finds all the compliance violations' do
        post_graphql(query, current_user: current_user)

        expect(compliance_violations).to contain_exactly(violation_output, violation2_output)
      end
    end

    context 'filtering the results' do
      context 'when given an array of project IDs' do
        it 'finds all the compliance violations' do
          post_graphql(query({ filters: { projectIds: [project.to_global_id.to_s] } }), current_user: current_user)

          expect(compliance_violations).to contain_exactly(violation_output)
        end
      end

      context 'when given merged at dates' do
        where(:merged_params, :result) do
          { 'mergedBefore' => 2.days.ago.to_date.iso8601 } | lazy { violation_output }
          { 'mergedAfter' => 2.days.ago.to_date.iso8601 } | lazy { violation2_output }
          { 'mergedBefore' => Date.current.iso8601, 'mergedAfter' => 2.days.ago.to_date.iso8601 } | lazy { violation2_output }
        end

        with_them do
          it 'finds all the compliance violations' do
            post_graphql(query({ filters: merged_params }), current_user: current_user)

            expect(compliance_violations).to contain_exactly(result)
          end
        end
      end
    end

    describe 'sorting and pagination' do
      let_it_be(:data_path) { [:group, :merge_request_violations] }

      let(:violation_ids_asc) { [violation_output['id'].to_i, violation2_output['id'].to_i] }
      let(:violation_ids_desc) { [violation2_output['id'].to_i, violation_output['id'].to_i] }

      def pagination_query(params)
        graphql_query_for(
          :group, { full_path: group.full_path }, query_nodes(:merge_request_violations, :id, include_pagination_info: true, args: params)
        )
      end

      def pagination_results_data(data)
        data.map { |merge_request_violations| merge_request_violations['id'].to_i }
      end

      where(:sort_param, :all_records) do
        :SEVERITY_LEVEL_ASC       | ref(:violation_ids_asc)
        :SEVERITY_LEVEL_DESC      | ref(:violation_ids_desc)
        :VIOLATION_REASON_ASC     | ref(:violation_ids_asc)
        :VIOLATION_REASON_DESC    | ref(:violation_ids_desc)
        :MERGE_REQUEST_TITLE_ASC  | ref(:violation_ids_asc)
        :MERGE_REQUEST_TITLE_DESC | ref(:violation_ids_desc)
        :MERGED_AT_ASC            | ref(:violation_ids_asc)
        :MERGED_AT_DESC           | ref(:violation_ids_desc)
      end

      with_them do
        it_behaves_like 'sorted paginated query' do
          let(:first_param) { 2 }
        end
      end
    end
  end
end
