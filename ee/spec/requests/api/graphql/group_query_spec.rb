# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting group information', feature_category: :subgroups do
  include GraphqlHelpers

  let(:user) { create(:user) }

  describe "Query group(fullPath)" do
    def group_query(group)
      graphql_query_for('group', 'fullPath' => group.full_path)
    end

    context 'when Group SSO is enforced' do
      let(:group) { create(:group, :private) }

      before do
        stub_licensed_features(group_saml: true)
        saml_provider = create(:saml_provider, enforced_sso: true, group: group)
        create(:group_saml_identity, saml_provider: saml_provider, user: user)
        group.add_guest(user)
      end

      it 'returns null data when not authorized' do
        post_graphql(group_query(group))

        expect(graphql_data['group']).to be_nil
      end

      it 'allows access via session' do
        post_graphql(group_query(group), current_user: user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(graphql_data['group']['id']).to eq(group.to_global_id.to_s)
      end

      it 'allows access via bearer token' do
        token = create(:personal_access_token, user: user).token
        post_graphql(group_query(group), headers: { 'Authorization' => "Bearer #{token}" })

        expect(response).to have_gitlab_http_status(:ok)
        expect(graphql_data['group']['id']).to eq(group.to_global_id.to_s)
      end
    end

    context 'when loading vulnerabilityGrades alongside with Vulnerability.userNotesCount' do
      let_it_be(:private_group) { create(:group, :private) }
      let_it_be(:public_group) { create(:group, :public) }

      let(:fields_public_group) do
        <<~QUERY
        vulnerabilityGrades {
          grade
          count
          projects {
            nodes {
              vulnerabilities {
                nodes {
                  id
                  userNotesCount
                }
              }
            }
          }
        }
        QUERY
      end

      let(:fields_private_group) do
        <<~QUERY
        vulnerabilityGrades {
          grade
          count
          projects {
            nodes {
              confirmedVulnerabilities: vulnerabilities(state: CONFIRMED) {
                nodes {
                  id
                  userNotesCount
                }
              }
              dismissedVulnerabilities: vulnerabilities(state: DISMISSED) {
                nodes {
                  id
                  userNotesCount
                }
              }
            }
          }
        }
        QUERY
      end

      let(:queries) do
        [
          { query: graphql_query_for('group', { 'fullPath' => private_group.full_path }, fields_private_group) },
          { query: graphql_query_for('group', { 'fullPath' => public_group.full_path }, fields_public_group) }
        ]
      end

      let_it_be(:public_project) { create(:project, group: public_group) }
      let_it_be(:private_project) { create(:project, group: private_group) }

      let_it_be(:vulnerability_1) { create(:vulnerability, :dismissed, :critical_severity, :with_notes, :with_finding, notes_count: 2, project: public_project) }
      let_it_be(:vulnerability_2) { create(:vulnerability, :confirmed, :high_severity, :with_notes, :with_finding, notes_count: 3, project: public_project) }
      let_it_be(:vulnerability_3) { create(:vulnerability, :dismissed, :medium_severity, :with_notes, :with_finding, notes_count: 4, project: private_project) }
      let_it_be(:vulnerability_4) { create(:vulnerability, :confirmed, :low_severity, :with_notes, :with_finding, notes_count: 7, project: private_project) }

      let_it_be(:vulnerability_statistic_1) { create(:vulnerability_statistic, :grade_c, project: public_project) }
      let_it_be(:vulnerability_statistic_2) { create(:vulnerability_statistic, :grade_d, project: private_project) }

      let(:first_graphql_data) do
        json_response.first['data']
      end

      let(:second_graphql_data) do
        json_response.last['data']
      end

      let(:expected_private_group_response) do
        [
          {
            'count' => 1,
            'grade' => 'D',
            'projects' => {
              'nodes' => [
                {
                  'confirmedVulnerabilities' => {
                    'nodes' => [
                      { 'id' => vulnerability_4.to_global_id.to_s, 'userNotesCount' => 7 }
                    ]
                  },
                  'dismissedVulnerabilities' => {
                    'nodes' => [
                      { 'id' => vulnerability_3.to_global_id.to_s, 'userNotesCount' => 4 }
                    ]
                  }
                }
              ]
            }
          },
          {
            'count' => 0,
            'grade' => 'C',
            'projects' => {
              'nodes' => []
            }
          }
        ]
      end

      let(:expected_public_group_response) do
        [
          {
            'count' => 0,
            'grade' => 'D',
            'projects' => {
              'nodes' => []
            }
          },
          {
            'count' => 1,
            'grade' => 'C',
            'projects' => {
              'nodes' => [
                {
                  'vulnerabilities' => {
                    'nodes' => [
                      { 'id' => vulnerability_1.to_global_id.to_s, 'userNotesCount' => 2 },
                      { 'id' => vulnerability_2.to_global_id.to_s, 'userNotesCount' => 3 }
                    ]
                  }
                }
              ]
            }
          }
        ]
      end

      before do
        public_group.add_developer(user)
        private_group.add_developer(user)
        stub_licensed_features(security_dashboard: true)

        post_multiplex(queries, current_user: user)
      end

      it 'finds vulnerability grades for only projects that were added to instance security dashboard', :aggregate_failures do
        expect(first_graphql_data.dig('group', 'vulnerabilityGrades')).to match_array(expected_private_group_response)
        expect(second_graphql_data.dig('group', 'vulnerabilityGrades')).to match_array(expected_public_group_response)
      end

      it 'returns a successful response', :aggregate_failures do
        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).to eq([nil, nil])
      end
    end

    context 'when loading multiple epics' do
      let_it_be(:group) { create(:group) }

      before do
        stub_licensed_features(epics: true)
        query_epics(1)
      end

      it 'can lookahead to eliminate N+1 queries', :use_clean_rails_memory_store_caching do
        create_list(:epic, 10, group: group)
        group.reload

        control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          query_epics(1)
        end.count

        expect { query_epics(10) }.not_to exceed_all_query_limit(control_count)
      end
    end

    def query_epics(number)
      epics_field = <<~NODE
        epics(first: #{number}) {
          edges {
            node {
              title
            }
          }
        }
      NODE

      post_graphql(
        graphql_query_for('group', { 'fullPath' => group.full_path }, epics_field),
        current_user: user
      )
    end

    context 'when loading release statistics' do
      let_it_be(:guest_user) { create(:user) }
      let_it_be(:public_user) { create(:user) }

      let(:query_fields) do
        <<~QUERY
        stats {
          releaseStats {
            releasesCount
            releasesPercentage
          }
        }
        QUERY
      end

      let(:query) do
        graphql_query_for('group', { 'fullPath' => group.full_path }, query_fields)
      end

      let(:release_stats) do
        graphql_data.with_indifferent_access.dig(:group, :stats, :releaseStats)
      end

      before do
        group.add_guest(guest_user)

        post_graphql(query, current_user: current_user)
      end

      shared_examples 'no access to release statistics' do
        it 'returns data about release utilization within the group' do
          expect(release_stats).to be_nil
        end
      end

      shared_examples 'full access to release statistics' do
        context 'when there are no releases' do
          it 'returns 0 for both statistics' do
            expect(release_stats).to match(
              releasesCount: 0,
              releasesPercentage: 0
            )
          end
        end

        context 'when there are some releases' do
          let_it_be(:subgroup) { create(:group, :private, parent: group) }
          let_it_be(:project_in_group) { create(:project, group: group) }
          let_it_be(:project_in_subgroup) { create(:project, group: subgroup) }
          let_it_be(:another_project_in_subgroup) { create(:project, group: subgroup) }
          let_it_be(:project_in_unrelated_group) { create(:project) }
          let_it_be(:release_1) { create(:release, project: project_in_group) }
          let_it_be(:release_2) { create(:release, project: project_in_subgroup) }
          let_it_be(:release_3) { create(:release, project: project_in_subgroup) }
          let_it_be(:release_4) { create(:release, project: project_in_unrelated_group) }

          it 'returns data about release utilization within the group' do
            expect(release_stats).to match(
              releasesCount: 3,
              releasesPercentage: 67
            )
          end
        end
      end

      shared_examples 'correct access to release statistics' do
        context 'when the user is not logged in' do
          let(:current_user) { nil }

          it_behaves_like 'no access to release statistics'
        end

        context 'when the user is not a member of the group' do
          let(:current_user) { public_user }

          it_behaves_like 'no access to release statistics'
        end

        context 'when the user is at least a guest' do
          let(:current_user) { guest_user }

          it_behaves_like 'full access to release statistics'
        end
      end

      context 'when the group is private' do
        let_it_be(:group) { create(:group, :private) }

        it_behaves_like 'correct access to release statistics'
      end

      context 'when the group is public' do
        let_it_be(:group) { create(:group, :public) }

        it_behaves_like 'correct access to release statistics'
      end
    end
  end

  describe 'pagination' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }
    let_it_be(:group) { create(:group, projects: [project_1, project_2]) }

    let(:data_path) { [:group, :codeCoverageActivities] }

    def pagination_query(params)
      graphql_query_for(
        :group, { full_path: group.full_path },
        <<~QUERY
        codeCoverageActivities(startDate: "#{start_date}" #{params}) {
          #{page_info}
          nodes { averageCoverage }
        }
        QUERY
      )
    end

    context 'when default sorting' do
      let_it_be(:cov_1) { create(:ci_daily_build_group_report_result, project: project_1, coverage: 77.0, group: group) }
      let_it_be(:cov_2) { create(:ci_daily_build_group_report_result, project: project_2, coverage: 88.8, date: 1.week.ago, group: group) }
      let_it_be(:cov_3) { create(:ci_daily_build_group_report_result, project: project_1, coverage: 66.6, date: 2.weeks.ago, group: group) }
      let_it_be(:cov_4) { create(:ci_daily_build_group_report_result, project: project_2, coverage: 99.9, date: 3.weeks.ago, group: group) }
      let_it_be(:cov_5) { create(:ci_daily_build_group_report_result, project: project_1, coverage: 44.4, date: 4.weeks.ago, group: group) }
      let_it_be(:cov_6) { create(:ci_daily_build_group_report_result, project: project_1, coverage: 100.0, date: 6.weeks.ago, group: group) }

      let(:start_date) { 5.weeks.ago.to_date.to_s }

      it_behaves_like 'sorted paginated query' do
        include_context 'no sort argument'

        let(:node_path) { ['averageCoverage'] }
        let(:first_param) { 2 }
        let(:all_records) { [cov_1, cov_2, cov_3, cov_4, cov_5].reverse.map(&:coverage) }
      end
    end
  end
end
