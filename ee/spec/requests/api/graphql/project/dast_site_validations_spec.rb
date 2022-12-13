# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).dastSiteValidations', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:dast_site_token1) { create(:dast_site_token, project: project) }
  let_it_be(:dast_site_token2) { create(:dast_site_token, project: project) }
  let_it_be(:dast_site_token3) { create(:dast_site_token, project: project) }
  let_it_be(:dast_site_token4) { create(:dast_site_token, project: project) }
  let_it_be(:dast_site_validation1) { create(:dast_site_validation, dast_site_token: dast_site_token1) }
  let_it_be(:dast_site_validation2) { create(:dast_site_validation, dast_site_token: dast_site_token2) }
  let_it_be(:dast_site_validation3) { create(:dast_site_validation, dast_site_token: dast_site_token3) }
  let_it_be(:dast_site_validation4) { create(:dast_site_validation, dast_site_token: dast_site_token4) }
  let_it_be(:current_user) { create(:user) }

  let(:query) do
    fields = all_graphql_fields_for('DastSiteValidation')

    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_nodes(:dast_site_validations, fields)
    )
  end

  subject do
    post_graphql(
      query,
      current_user: current_user,
      variables: {
        fullPath: project.full_path
      }
    )
  end

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  context 'when a user does not have access to the project' do
    it 'returns a null project' do
      subject

      expect(graphql_data_at(:project)).to be_nil
    end
  end

  context 'when a user does not have access to dast_site_validations' do
    it 'returns an empty nodes array' do
      project.add_guest(current_user)

      subject

      expect(graphql_data_at(:project, :dast_site_validations, :nodes)).to be_empty
    end
  end

  context 'when a user has access to dast_site_validations' do
    before do
      project.add_developer(current_user)
    end

    let(:data_path) { [:project, :dast_site_validations] }

    def pagination_results_data(dast_site_validations)
      dast_site_validations.map { |dast_site_validation| dast_site_validation['id'] }
    end

    it_behaves_like 'sorted paginated query' do
      include_context 'no sort argument'

      let(:first_param) { 3 }

      let(:all_records) do
        [
          dast_site_validation4,
          dast_site_validation3,
          dast_site_validation2,
          dast_site_validation1
        ].map { |validation| global_id_of(validation).to_s }
      end
    end

    it 'avoids N+1 queries', :aggregate_failures do
      control = ActiveRecord::QueryRecorder.new do
        post_graphql(query, current_user: current_user)
      end

      5.times do
        dast_site_token = create(:dast_site_token, project: project)

        create(:dast_site_validation, dast_site_token: dast_site_token)
      end

      expect { subject }.not_to exceed_query_limit(control)
      expect(graphql_data_at(:project, :dast_site_validations, :nodes).size).to eq(9)
    end
  end

  def pagination_query(arguments)
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_nodes(:dast_site_validations, 'id', include_pagination_info: true, args: arguments)
    )
  end
end
