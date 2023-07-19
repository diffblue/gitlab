# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting the project compliance standards adherence for a group',
  feature_category: :compliance_management do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:sub_group) { create(:group, parent: group) }
  let_it_be(:project_1) { create(:project, group: group) }
  let_it_be(:project_2) { create(:project, group: group) }
  let_it_be(:project_without_adherence) { create(:project, group: group) }
  let_it_be(:sub_group_project) { create(:project, group: sub_group) }
  let_it_be(:project_outside_group) { create(:project, group: create(:group)) }

  let_it_be(:adherence_1) do
    create(:compliance_standards_adherence, :gitlab, project: project_1,
      check_name: :prevent_approval_by_merge_request_author)
  end

  let_it_be(:adherence_2) do
    create(:compliance_standards_adherence, :gitlab, :fail, project: project_2,
      check_name: :prevent_approval_by_merge_request_author)
  end

  let_it_be(:adherence_3) do
    create(:compliance_standards_adherence, :gitlab, project: sub_group_project,
      check_name: :prevent_approval_by_merge_request_author)
  end

  let_it_be(:adherence_4) do
    create(:compliance_standards_adherence, :gitlab, project: project_outside_group,
      check_name: :prevent_approval_by_merge_request_author)
  end

  let(:fields) do
    <<~GRAPHQL
      nodes {
        id
        updatedAt
        status
        checkName
        standard
        project {
          id
          name
        }
      }
    GRAPHQL
  end

  let(:adherence_1_output) do
    get_compliance_standards_adherence_values(adherence_1)
  end

  let(:adherence_2_output) do
    get_compliance_standards_adherence_values(adherence_2)
  end

  let(:adherence_3_output) do
    get_compliance_standards_adherence_values(adherence_3)
  end

  let(:project_adherence) { graphql_data_at(:group, :project_compliance_standards_adherence, :nodes) }

  def get_compliance_standards_adherence_values(project_adherence)
    {
      'id' => project_adherence.to_global_id.to_s,
      'updatedAt' => project_adherence.updated_at.iso8601,
      'status' => ::Types::Projects::ComplianceStandards::AdherenceStatusEnum
                    .values[project_adherence.status.upcase].graphql_name,
      'checkName' => ::Types::Projects::ComplianceStandards::AdherenceCheckNameEnum
                    .values[project_adherence.check_name.upcase].graphql_name,
      'standard' => ::Types::Projects::ComplianceStandards::AdherenceStandardEnum
                       .values[project_adherence.standard.upcase].graphql_name,
      'project' => {
        'id' => project_adherence.project.to_global_id.to_s,
        'name' => project_adherence.project.name
      }
    }
  end

  def query(params = {})
    graphql_query_for(
      :group, { full_path: group.full_path },
      query_graphql_field("projectComplianceStandardsAdherence", params, fields)
    )
  end

  shared_examples 'returns nil' do
    it do
      post_graphql(query, current_user: current_user)

      expect(project_adherence).to be_nil
    end
  end

  context 'when the user is unauthorized' do
    context 'when not part of the group' do
      it_behaves_like 'returns nil'
    end

    context 'with maintainer access' do
      before_all do
        group.add_maintainer(current_user)
      end

      it_behaves_like 'returns nil'
    end
  end

  context 'when the user is authorized' do
    before_all do
      group.add_owner(current_user)
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    context 'without any filters' do
      it 'finds all the project compliance standards adherence for the group and its subgroups' do
        post_graphql(query, current_user: current_user)

        expect(project_adherence).to match_array([adherence_1_output, adherence_2_output, adherence_3_output])
      end
    end

    context 'with filters' do
      context 'when given an array of project IDs' do
        context 'when projects have compliance standards adherence' do
          it 'finds the filtered project compliance standards adherence' do
            post_graphql(query({ filters: { projectIds: [project_1.to_global_id.to_s, project_2.to_global_id.to_s] } }),
              current_user: current_user)

            expect(project_adherence).to contain_exactly(adherence_1_output, adherence_2_output)
          end
        end

        context 'with a non existent project id' do
          it 'returns an empty array' do
            post_graphql(query({ filters: { projectIds: ["gid://gitlab/Project/#{non_existing_record_id}"] } }),
              current_user: current_user)

            expect(project_adherence).to be_empty
          end
        end

        context 'with empty project id' do
          it 'finds all the project compliance standards adherence for the group and its subgroups' do
            post_graphql(query({ filters: { projectIds: [] } }), current_user: current_user)

            expect(project_adherence).to match_array([adherence_1_output, adherence_2_output, adherence_3_output])
          end
        end

        context 'when project does not have an adherence record associated with it' do
          it 'returns an empty array' do
            post_graphql(query({ filters: { projectIds: [project_without_adherence.to_global_id.to_s] } }),
              current_user: current_user)

            expect(project_adherence).to be_empty
          end
        end
      end

      context 'when given a check_name' do
        context 'when the input is valid' do
          it 'finds the filtered project compliance standards adherence' do
            check_name = :PREVENT_APPROVAL_BY_MERGE_REQUEST_AUTHOR

            post_graphql(query({ filters: { checkName: check_name } }), current_user: current_user)

            expect(project_adherence).to match_array([adherence_1_output, adherence_2_output, adherence_3_output])
          end
        end

        context 'when the input is not valid' do
          it 'finds the filtered project compliance standards adherence' do
            post_graphql(query({ filters: { checkName: 'NON_EXISTING_CHECK_NAME' } }), current_user: current_user)

            expect_graphql_errors_to_include(
              "Argument 'checkName' on InputObject 'ComplianceStandardsAdherenceInput' has an invalid value")
          end
        end
      end

      context 'when given a standard' do
        context 'when the input is valid' do
          it 'finds the filtered project compliance standards adherence' do
            post_graphql(query({ filters: { standard: :GITLAB } }), current_user: current_user)

            expect(project_adherence).to match_array([adherence_1_output, adherence_2_output, adherence_3_output])
          end
        end

        context 'when the input is not valid' do
          it 'finds the filtered project compliance standards adherence' do
            post_graphql(query({ filters: { standard: 'NON_EXISTING_STANDARD' } }), current_user: current_user)

            expect_graphql_errors_to_include(
              "Argument 'standard' on InputObject 'ComplianceStandardsAdherenceInput' has an invalid value")
          end
        end
      end
    end
  end
end
