# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.group(fullPath).projects.dastProfiles.dastProfileSchedule', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }
  let_it_be(:dast_profile_schedule) { create(:dast_profile_schedule, project: project, dast_profile: dast_profile, owner: current_user) }

  let_it_be(:project2) { create(:project, :repository, group: group) }
  let_it_be(:dast_profile2) { create(:dast_profile, project: project2) }
  let_it_be(:dast_profile_schedule2) { create(:dast_profile_schedule, project: project2, dast_profile: dast_profile2, owner: current_user) }

  let(:query) do
    %(
      query {
        group(fullPath: "#{group.full_path}") {
          projects {
            edges {
              node {
                __typename
                id
                dastProfiles {
                  edges {
                    node {
                      dastProfileSchedule {
                        #{all_graphql_fields_for('DastProfileSchedule')}
                      }
                    }
                  }
                }
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

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  context 'when a user has access to dast_profile_schedule' do
    let_it_be(:plan_limits) { create(:plan_limits, :default_plan) }

    before do
      project.add_developer(current_user)
    end

    it 'returns a dast_profile_schedule' do
      r = run_query(query).to_h
      schedule = graphql_dig_at(r, :data,
                                   :group,
                                   :projects, :edges, :node,
                                   :dast_profiles, :edges, :node,
                                   :dast_profile_schedule, 0)

      expect(schedule).to include('ownerValid' => eq(true))
    end

    it_behaves_like 'query dastProfiles.dastProfileSchedule shared examples', :avoids_n_plus_1_queries, create_new_project: true
  end
end
