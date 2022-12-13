# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).dastProfiles.dastProfileSchedule',
feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers
  let_it_be(:plan_limits) { create(:plan_limits, :default_plan) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }
  let_it_be(:dast_profile_schedule) { create(:dast_profile_schedule, project: project, dast_profile: dast_profile, owner: current_user) }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          dastProfiles {
            edges {
              node {
                  dastProfileSchedule { #{all_graphql_fields_for('DastProfileSchedule')} }
              }
            }
          }
        }
      }
    )
  end

  def run_query(query)
    run_with_clean_state(query,
                         context: { current_user: current_user },
                         variables: {})
  end

  subject { post_graphql(query, current_user: current_user) }

  let(:project_data) { graphql_data_at(:project) }
  let(:dast_profile_data) { graphql_data_at(:project, :dast_profiles, :edges) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  context 'when a user does not have access to the project' do
    it 'returns a null project' do
      subject

      expect(project_data).to be_nil
    end
  end

  context 'when a user does not have access to dast_profile' do
    before do
      project.add_guest(current_user)
    end

    it 'returns an empty dast_profile' do
      subject

      expect(dast_profile_data).to be_empty
    end
  end

  context 'when a user has access to dast_profile_schedule' do
    before do
      project.add_developer(current_user)
    end

    it 'returns a dast_profile_schedule' do
      subject

      expect(dast_profile_data[0].dig('node', 'dastProfileSchedule', 'ownerValid')).to eq(true)
    end

    it_behaves_like 'query dastProfiles.dastProfileSchedule shared examples', :avoids_n_plus_1_queries
  end
end
