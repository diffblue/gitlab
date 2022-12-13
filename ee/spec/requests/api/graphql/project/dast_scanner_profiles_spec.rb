# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).dastScannerProfiles', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile) }
  let_it_be(:project) { dast_scanner_profile.project }
  let_it_be(:dast_scanner_profile_different_project) { create(:dast_scanner_profile) }
  let_it_be(:project_2) { dast_scanner_profile_different_project.project }
  let_it_be(:current_user) { create(:user) }

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('dastScannerProfiles', {}, "nodes { #{all_graphql_fields_for('DastScannerProfile')} }")
    )
  end

  let(:response_data) do
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
    describe 'project response' do
      subject { response_data.dig('project') }

      it { is_expected.to be_nil }
    end
  end

  context 'when the user can run a dast scan' do
    before do
      project.add_guest(current_user)
      project_2.add_guest(current_user)
    end

    describe 'dast scanner profiles' do
      subject { response_data.dig('project', 'dastScannerProfiles', 'nodes') }

      it { is_expected.to be_empty }
    end
  end

  context 'when a user has access to multiple projects' do
    before do
      project.add_developer(current_user)
      project_2.add_developer(current_user)
    end

    describe 'dast scanner profiles' do
      subject { response_data.dig('project', 'dastScannerProfiles', 'nodes') }

      it 'returns only the dast_scanner_profile for the requested project' do
        expect(subject.length).to eq(1)
        expect(subject.first['id']).to eq(Gitlab::GlobalId.build(dast_scanner_profile).to_s)
      end
    end
  end

  context 'when a user has access dast_scanner_profiles' do
    before do
      project.add_developer(current_user)
    end

    describe 'dast scanner profiles' do
      subject { response_data.dig('project', 'dastScannerProfiles', 'nodes') }

      it { is_expected.not_to be_empty }
    end

    describe 'first dast scanner profile id' do
      subject { response_data.dig('project', 'dastScannerProfiles', 'nodes').first['id'] }

      it { is_expected.to eq(dast_scanner_profile.to_global_id.to_s) }
    end
  end
end
