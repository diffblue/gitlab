# frozen_string_literal: true

RSpec.shared_examples 'graphql issue list request spec EE' do
  let(:issue_ids) { graphql_dig_at(issues_data, :id) }
  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('issues'.classify)}
      }
    QUERY
  end

  describe 'sorting and pagination' do
    context 'when sorting by weight' do
      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { :WEIGHT_ASC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list([issue_b, issue_c, issue_d, issue_e, issue_a]) }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { :WEIGHT_DESC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list([issue_e, issue_d, issue_c, issue_b, issue_a]) }
        end
      end
    end

    context 'when sorting by published incident' do
      before_all do
        create(:status_page_published_incident, issue: issue_a)
        create(:status_page_published_incident, issue: issue_c)
      end

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)  { :PUBLISHED_ASC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list([issue_e, issue_d, issue_b, issue_c, issue_a]) }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)  { :PUBLISHED_DESC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list([issue_a, issue_c, issue_e, issue_d, issue_b]) }
        end
      end
    end

    context 'when sorting by sla due' do
      let_it_be(:sla_issue1) { create(:issue, :incident, project: public_project) }
      let_it_be(:sla_issue2) { create(:issue, :incident, project: public_project) }
      let_it_be(:sla_issue3) { create(:issue, :incident, project: public_project) }
      let_it_be(:sla_issue4) { create(:issue, :incident, project: public_project) }
      let_it_be(:sla_issue5) { create(:issue, :incident, project: public_project) }

      let(:sla_issues) { [sla_issue1, sla_issue2, sla_issue3, sla_issue4, sla_issue5] }
      let(:issue_filter_params) { { iids: sla_issues.map { |issue| issue.iid.to_s } } }

      before_all do
        create(:issuable_sla, issue: sla_issue1, due_at: 1.month.ago)
        create(:issuable_sla, issue: sla_issue5, due_at: 2.months.ago)
      end

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)  { :SLA_DUE_AT_ASC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list([sla_issue5, sla_issue1, sla_issue4, sla_issue3, sla_issue2]) }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param)  { :SLA_DUE_AT_DESC }
          let(:first_param) { 2 }
          let(:all_records) { to_gid_list([sla_issue1, sla_issue5, sla_issue4, sla_issue3, sla_issue2]) }
        end
      end
    end
  end

  describe 'filtering' do
    context 'when filtering by weight' do
      context 'when filtering for all issues with an assigned weight' do
        let(:issue_filter_params) do
          { weight_wildcard_id: :ANY }
        end

        it 'returns all issues with an assigned weight' do
          post_query

          expect(issue_ids).to match_array([issue_b, issue_c, issue_d, issue_e].map { |i| i.to_gid.to_s })
        end
      end

      context 'when filtering for all issues without an assigned weight' do
        let(:issue_filter_params) do
          { weight_wildcard_id: :NONE }
        end

        it 'returns all issues without an assigned weight' do
          post_query

          expect(issue_ids).to match_array([issue_a].map { |i| i.to_gid.to_s })
        end
      end

      context 'when both weight and weight_wildcard_id filters are provided' do
        let(:issue_filter_params) do
          { weight: "4", weight_wildcard_id: :ANY }
        end

        it 'returns a mutually exclusive param error' do
          post_query

          expect_graphql_errors_to_include(
            'only one of [weight, weightWildcardId] arguments is allowed at the same time.'
          )
        end
      end
    end

    context 'when filtering by iteration' do
      let_it_be(:cadence) do
        create(:iterations_cadence, group: group1, active: true, duration_in_weeks: 1, title: 'one week iterations')
      end

      let_it_be(:iteration) do
        create(
          :current_iteration,
          :skip_future_date_validation,
          iterations_cadence: cadence,
          title: 'one test',
          group: group1,
          start_date: 1.day.ago,
          due_date: Date.today)
      end

      let_it_be(:project) { create(:project, group: group1) }
      let_it_be(:issue_1) { create(:issue, project: project, iteration: iteration) }
      let_it_be(:issue_2) { create(:issue, project: project, iteration: iteration) }
      let(:issues_with_cadence) { [issue_1, issue_2].map { |i| i.to_gid.to_s } }

      context 'when filtering for issues in an iteration' do
        let(:issue_filter_params) do
          { iteration_title: iteration.title }
        end

        it 'returns all issues in the iteration' do
          post_query

          expect(issue_ids).to match_array([issue_1, issue_2].map { |i| i.to_gid.to_s })
        end
      end

      context 'when filtering for issues in an iteration by iteration cadence' do
        let(:issue_filter_params) do
          { iteration_cadence_id: [cadence.to_gid.to_s] }
        end

        it 'returns all issues in the iteration' do
          post_query

          expect(issue_ids).to match_array(issues_with_cadence)
        end
      end
    end

    context 'when filtering by epic' do
      let_it_be(:group) { create(:group) }
      let_it_be(:epic_a) { create(:epic, group: group1) }
      let_it_be(:epic_b) { create(:epic, group: group1) }

      before_all do
        issue_a.epic = epic_a
        issue_c.epic = epic_b
      end

      context 'when filtering for all issues with epics' do
        let(:issue_filter_params) do
          { epic_wildcard_id: :ANY }
        end

        it 'returns all issues with epics' do
          post_query

          expect(issue_ids).to match_array([issue_a, issue_c].map { |i| i.to_gid.to_s })
        end
      end

      context 'when filtering for issues without epics' do
        let(:issue_filter_params) do
          { epic_wildcard_id: :NONE }
        end

        it 'returns all issues without epics' do
          post_query

          expect(issue_ids).to match_array([issue_b, issue_d, issue_e].map { |i| i.to_gid.to_s })
        end
      end

      context 'when both epic_id and epic_wildcard_id filters are provided' do
        let(:issue_filter_params) do
          { epic_id: epic_a.to_gid, epic_wildcard_id: :ANY }
        end

        it 'returns a mutually exclusive param error' do
          post_query

          expect_graphql_errors_to_include(
            'only one of [epicId, epicWildcardId] arguments is allowed at the same time.'
          )
        end
      end
    end
  end

  describe 'blocked' do
    let_it_be(:link1) { create(:issue_link, source: issue_a, target: issue_b, link_type: 'blocks') }
    let_it_be(:link2) { create(:issue_link, source: issue_c, target: issue_b, link_type: 'blocks') }
    let_it_be(:link3) { create(:issue_link, source: issue_a, target: issue_d, link_type: 'blocks') }

    let(:fields) do
      <<~QUERY
        nodes {
          id
          blocked
          blockedByCount
          blockedByIssues {
            nodes { id }
          }
        }
      QUERY
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_query
      end
    end

    it 'uses the LazyLinksAggregate service' do
      expect(::Gitlab::Graphql::Aggregations::Issues::LazyLinksAggregate).to receive(:new).exactly(5).times

      post_query
    end

    it 'returns the correct blocked count result', :aggregate_failures do
      post_query

      expect_blocked_count(issue_a, false, 0)
      expect_blocked_count(issue_b, true, 2)
      expect_blocked_count(issue_c, false, 0)
      expect_blocked_count(issue_d, true, 1)
      expect_blocked_count(issue_e, false, 0)
    end

    it 'returns the correct blocked issue detail result', :aggregate_failures do
      post_query

      expect_blocking_issues(issue_a, [])
      expect_blocking_issues(issue_b, [issue_a, issue_c])
      expect_blocking_issues(issue_c, [])
      expect_blocking_issues(issue_d, [issue_a])
      expect_blocking_issues(issue_e, [])
    end

    def expect_blocking_issues(issue, expected_blocking_issues)
      node = issues_data.find { |r| r['id'] == issue.to_global_id.to_s }

      expect(node['blockedByIssues']['nodes']).to match_array(
        expected_blocking_issues.map { |i| { 'id' => i.to_global_id.to_s } }
      )
    end

    def expect_blocked_count(issue, expected_blocked, expected_blocked_count)
      node = issues_data.find { |r| r['id'] == issue.to_global_id.to_s }

      expect(node['blocked']).to eq(expected_blocked)
      expect(node['blockedByCount']).to eq(expected_blocked_count)
    end
  end

  describe 'related_vulnerabilities' do
    let(:fields) do
      <<~QUERY
        nodes {
          id
          relatedVulnerabilities {
            nodes {
              id
              title
            }
          }
        }
      QUERY
    end

    before do
      stub_licensed_features(security_dashboard: true)
      issues.each_with_index do |issue, i|
        issue.update!(related_vulnerabilities: [create(:vulnerability, project: issue.project, title: "vuln#{i + 1}")])
      end
    end

    it 'avoids N+1 queries', :aggregate_failures do
      post_query # warm-up

      control = ActiveRecord::QueryRecorder.new { post_query }

      expect(issues_data.count).to eq(5)
      vulnerability_titles = graphql_dig_at(issues_data, :relatedVulnerabilities, :nodes, :title)
      expect(vulnerability_titles).to match_array(%w[vuln1 vuln2 vuln3 vuln4 vuln5])

      create(
        :issue,
        project: public_project,
        related_vulnerabilities: [create(:vulnerability, project: public_project, title: 'vuln6')]
      )

      expect { post_query }.not_to exceed_query_limit(control)

      expect(issues_data.count).to eq(6)
      vulnerability_titles = graphql_dig_at(issues_data, :relatedVulnerabilities, :nodes, :title)
      expect(vulnerability_titles).to match_array(%w[vuln1 vuln2 vuln3 vuln4 vuln5 vuln6])
    end
  end

  def to_gid_list(instance_list)
    instance_list.map { |instance| instance.to_gid.to_s }
  end

  def issues_data
    graphql_data.dig(*issue_nodes_path)
  end
end
