# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting the compliance violations for a group' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:project2) { create(:project, :repository, group: group) }
  let_it_be(:project_outside_group) { create(:project, :repository, group: create(:group)) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project, state: :merged) }
  let_it_be(:merge_request2) { create(:merge_request, source_project: project2, target_project: project2, state: :merged) }
  let_it_be(:merge_request_outside_group) { create(:merge_request, source_project: project_outside_group, target_project: project_outside_group, state: :merged) }
  let_it_be(:compliance_violation) { create(:compliance_violation, :approved_by_committer, severity_level: :low, merge_request: merge_request) }
  let_it_be(:compliance_violation2) { create(:compliance_violation, :approved_by_merge_request_author, severity_level: :high, merge_request: merge_request2) }
  let_it_be(:compliance_violation_outside_group) { create(:compliance_violation, :approved_by_committer, merge_request: merge_request_outside_group) }

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

  context 'when feature is disabled' do
    before do
      stub_feature_flags(compliance_violations_graphql_type: false)
    end

    it 'returns empty' do
      post_graphql(query, current_user: current_user)

      expect(compliance_violations).to be_empty
    end
  end

  context 'when feature is enabled' do
    before do
      stub_feature_flags(compliance_violations_graphql_type: true)
    end

    context 'when the user is unauthorized' do
      it 'returns empty' do
        post_graphql(query, current_user: current_user)

        expect(compliance_violations).to be_empty
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
    end
  end
end
