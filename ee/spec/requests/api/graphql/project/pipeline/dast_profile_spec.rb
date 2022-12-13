# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pipeline(iid).dastProfile',
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
          pipeline(iid: "#{pipeline.iid}") {
            dastProfile {
             #{all_graphql_fields_for('DastProfile')}
            }
          }
        }
      }
    )
  end

  subject { post_graphql(query, current_user: current_user) }

  let(:dast_profile_data) { graphql_data_at(:project, :pipeline, :dast_profile) }

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

    context 'when user is member of the project' do
      before do
        project.add_developer(current_user)
      end

      it 'returns the dast profile data' do
        subject

        expect(dast_profile_data['name']).to eq(dast_profile.name)
      end

      it 'avoids N+1 queries' do
        control = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: current_user)
        end

        create_list(:ci_pipeline, 5, :failed, project: project, dast_profile: dast_profile)

        expect { subject }.not_to exceed_query_limit(control)
      end
    end

    context 'when user is not member of the project' do
      it 'does not return dast profile data' do
        subject

        expect(dast_profile_data).to be_nil
      end
    end

    context 'when feature flag is not enabled' do
      it 'returns the dast profile data' do
        subject

        expect(dast_profile_data).to be_nil
      end
    end
  end
end
