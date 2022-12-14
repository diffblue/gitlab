# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipelines.dastProfile',
feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project, dast_profile: dast_profile) }
  let_it_be(:current_user) { create(:user) }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipelines {
            edges {
              node {
                dastProfile {
                  #{all_graphql_fields_for('DastProfile')}
                }
              }
            }
          }
        }
      }
    )
  end

  subject { post_graphql(query, current_user: current_user) }

  let(:pipelines_data) { graphql_data_at(:project, :pipelines, :edges, :node) }
  let(:dast_profile_data) { graphql_dig_at(pipelines_data, :dastProfile) }

  context 'when feature is not licensed' do
    it 'does not return dast profile data' do
      subject

      expect(dast_profile_data).to be_nil
    end
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(security_on_demand_scans: true)
    end

    context 'when user is not member of the project' do
      it 'does not return dast profile data' do
        subject

        expect(dast_profile_data).to be_nil
      end
    end

    context 'when user is member of the project' do
      before do
        project.add_developer(current_user)
      end

      it 'returns the dast profile data' do
        subject

        expect(dast_profile_data.first['name']).to eq(dast_profile.name)
      end

      it 'avoids N+1 queries', :aggregate_failures do
        control = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: current_user)
        end

        5.times do
          dast_profile = create(:dast_profile, project: project)
          create(:ci_pipeline, :success, project: project, dast_profile: dast_profile)
        end

        expect { subject }.not_to exceed_query_limit(control)
        expect(dast_profile_data.size).to eq(6)
      end
    end
  end
end
