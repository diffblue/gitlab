# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting external status checks for a branch rule', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:branch_rule) { create(:protected_branch) }
  let_it_be(:project) { branch_rule.project }
  let_it_be(:external_status_check) do
    create(:external_status_check, project: project, protected_branches: [branch_rule])
  end

  let(:variables) { { path: project.full_path } }
  let(:fields) { all_graphql_fields_for('ExternalStatusCheck') }
  let(:external_status_check_data) { external_status_checks_data.first }
  let(:branch_rules_data) { graphql_data_at('project', 'branchRules', 'nodes') }
  let(:external_status_checks_data) do
    graphql_data_at('project', 'branchRules', 'nodes', 0, 'externalStatusChecks', 'nodes')
  end

  let(:query) do
    <<~GQL
    query($path: ID!) {
      project(fullPath: $path) {
        branchRules {
          nodes {
            externalStatusChecks {
              nodes {
                #{fields}
              }
            }
          }
        }
      }
    }
    GQL
  end

  specify { expect(ProtectedBranch.count).to eq(1) }

  context 'when the user does not have read_external_status_check permission' do
    before do
      project.add_guest(current_user)
      post_graphql(query, current_user: current_user, variables: variables)
    end

    it_behaves_like 'a working graphql query' do
      it 'hides external_status_checks_data' do
        expect(external_status_checks_data).not_to be_present
      end
    end
  end

  context 'when the user does have read_external_status_check permission' do
    before do
      project.add_maintainer(current_user)
      post_graphql(query, current_user: current_user, variables: variables)
    end

    it_behaves_like 'a working graphql query' do
      it 'returns external_status_checks_data' do
        expect(external_status_checks_data).to be_an(Array)
        expect(external_status_checks_data.size).to eq(1)

        expect(external_status_check_data['id']).to eq(external_status_check.to_global_id.to_s)

        expect(external_status_check_data['name']).to eq(external_status_check.name)

        expect(external_status_check_data['externalUrl']).to eq(external_status_check.external_url)
      end
    end
  end
end
