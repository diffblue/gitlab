# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).dastSiteProfiles', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:current_user) { create(:user) }

  let(:query) do
    %(
      query project($fullPath: ID!) {
        project(fullPath: $fullPath) {
          dastSiteProfiles(first: 3) {
            pageInfo {
              hasNextPage
            }
            nodes { #{all_graphql_fields_for('DastSiteProfile')} }
          }
        }
      }
    )
  end

  let(:project_response) { subject.dig('project') }
  let(:dast_site_profiles_response) { project_response.dig('dastSiteProfiles') }
  let(:first_dast_site_profile_response) { dast_site_profiles_response.dig('nodes', 0) }

  subject do
    post_graphql(
      query,
      current_user: current_user,
      variables: {
        fullPath: project.full_path
      }
    )
    graphql_data
  end

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  context 'when a user does not have access to the project' do
    it 'returns a null project' do
      expect(project_response).to be_nil
    end
  end

  context 'when a user does not have access to dast_site_profiles' do
    it 'returns an empty edges array' do
      project.add_guest(current_user)

      expect(dast_site_profiles_response['nodes']).to be_empty
    end
  end

  context 'when a user has access dast_site_profiles' do
    before do
      project.add_developer(current_user)
    end

    it 'returns populated edges array' do
      expect(dast_site_profiles_response['nodes']).not_to be_empty
    end

    it 'returns a populated edges array containing a dast_site_profile associated with the project' do
      expect(first_dast_site_profile_response['id']).to eq(dast_site_profile.to_global_id.to_s)
    end

    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new do
        post_graphql(
          query,
          current_user: current_user,
          variables: {
            fullPath: project.full_path
          }
        )
      end

      create_list(:dast_site_profile, 2, project: project)

      expect { subject }.not_to exceed_query_limit(control)
    end

    context 'when there are fewer dast_site_profiles than the page limit' do
      it 'indicates there are no more pages available' do
        expect(dast_site_profiles_response.dig('pageInfo', 'hasNextPage')).to be(false)
      end
    end

    context 'when there are more dast_site_profiles than the page limit' do
      it 'indicates there are more pages available' do
        create_list(:dast_site_profile, 5, project: project)

        expect(dast_site_profiles_response.dig('pageInfo', 'hasNextPage')).to be(true)
      end
    end

    context 'when on demand scan licensed feature is not available' do
      it 'returns an empty edges array' do
        stub_licensed_features(security_on_demand_scans: false)

        expect(dast_site_profiles_response['nodes']).to be_empty
      end
    end
  end
end
