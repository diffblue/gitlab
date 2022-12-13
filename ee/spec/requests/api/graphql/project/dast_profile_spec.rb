# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).dastProfile', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }

  let(:query) do
    fields = all_graphql_fields_for('DastProfile')

    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_graphql_field(:dast_profile, { id: global_id_of(dast_profile) }, fields)
    )
  end

  subject do
    post_graphql(query, current_user: current_user)
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

  context 'when a user does not have access to the dast_profile' do
    before do
      project.add_guest(current_user)
    end

    it 'returns a null dast_profile' do
      subject

      expect(graphql_data_at(:project, :dast_profile)).to be_nil
    end
  end

  context 'when a user has access to the dast_profile' do
    before do
      project.add_developer(current_user)
    end

    it 'returns a dast_profile' do
      subject

      expect(graphql_data_at(:project, :dast_profile, :id)).to eq(dast_profile.to_global_id.to_s)
    end

    context 'when on demand scan licensed feature is not available' do
      before do
        stub_licensed_features(security_on_demand_scans: false)
      end

      it 'returns a null dast_profile' do
        subject

        expect(graphql_data_at(:project, :dast_profile)).to be_nil
      end
    end
  end
end
