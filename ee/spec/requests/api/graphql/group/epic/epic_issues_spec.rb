# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting issues for an epic', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:confidential_issue) { create(:issue, :confidential, project: project) }
  let_it_be(:epic_issue) { create(:epic_issue, epic: epic, issue: issue, relative_position: 3) }
  let_it_be(:epic_issue2) { create(:epic_issue, epic: epic, issue: confidential_issue, relative_position: 5) }

  let(:epics_data) { graphql_data['group']['epics']['edges'] }

  let(:epic_node) do
    <<~NODE
      edges {
        node {
          iid
          issues {
            edges {
              node {
                id
              }
            }
          }
        }
      }
    NODE
  end

  def epic_query(params = {}, epic_fields = epic_node)
    graphql_query_for("group", { "fullPath" => group.full_path },
                       query_graphql_field("epics", params, epic_fields)
    )
  end

  def issue_ids(epics = epics_data)
    node_array(epics).to_h do |node|
      [node['iid'].to_i, node_array(node['issues']['edges'], 'id')]
    end
  end

  def first_epic_issues_page_info
    epics_data.first['node']['issues']['pageInfo']
  end

  context 'when epics are enabled' do
    before do
      stub_licensed_features(epics: true)
    end

    it 'does not return inaccessible issues' do
      post_graphql(epic_query(iid: epic.iid), current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(issue_ids[epic.iid]).to be_empty
    end

    context 'when user has access to the issue project' do
      before do
        project.add_developer(user)
      end

      it 'returns issues in this project' do
        post_graphql(epic_query(iid: epic.iid), current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(issue_ids[epic.iid]).to match_array [issue.to_global_id.to_s, confidential_issue.to_global_id.to_s]
      end

      context 'pagination' do
        let(:data_path) { %i[group epics nodes] + [0] + %i[issues] }

        def pagination_query(args)
          epic_query({ iid: epic.iid }, epic_fields(args))
        end

        def epic_fields(args)
          query_graphql_field(:nodes, query_nodes(:issues, :id, args: args, include_pagination_info: true))
        end

        it_behaves_like 'sorted paginated query' do
          include_context 'no sort argument'

          let(:current_user) { user }
          let(:first_param) { 1 }
          let(:all_records) { [issue, confidential_issue].map { |i| global_id_of(i).to_s } }
        end
      end
    end

    context 'when user is guest' do
      before do
        project.add_guest(user)
      end

      it 'filters out confidential issues' do
        post_graphql(epic_query(iid: epic.iid), current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        expect(issue_ids[epic.iid]).to eq [issue.to_global_id.to_s]
      end
    end

    context 'when issues from multiple epics are queried' do
      let_it_be(:epic2) { create(:epic, group: group) }
      let_it_be(:issue2) { create(:issue, project: project) }
      let_it_be(:epic_issue3) { create(:epic_issue, epic: epic2, issue: issue2, relative_position: 3) }

      let(:params) { { iids: [epic.iid, epic2.iid] } }

      it 'returns issues for each epic' do
        project.add_developer(user)
        post_graphql(epic_query(params), current_user: user)

        expect(response).to have_gitlab_http_status(:success)
        result = issue_ids
        expect(result[epic.iid]).to match_array [issue.to_global_id.to_s, confidential_issue.to_global_id.to_s]
        expect(result[epic2.iid]).to match_array [issue2.to_global_id.to_s]
      end

      it 'does limited number of N+1 queries' do
        # extra queries:
        # epic_issues - for each epic issues are loaded ordered by relatve_position
        # issue_assignees - issue policy checks if user is between issue assignees
        # when https://gitlab.com/gitlab-org/gitlab/-/issues/353375 is fixed, we can
        # preload also issue assignees
        extra_queries_count = 2

        # warm-up query
        post_graphql(epic_query(iid: epic.iid), current_user: user)

        control_count = ActiveRecord::QueryRecorder.new(query_recorder_debug: true) do
          post_graphql(epic_query(iid: epic.iid), current_user: user)
        end

        expect do
          post_graphql(epic_query(params), current_user: user)
        end.not_to exceed_query_limit(control_count).with_threshold(extra_queries_count)

        expect(graphql_errors).to be_nil
      end
    end
  end

  context 'when epics are disabled' do
    before do
      stub_licensed_features(epics: false)
    end

    it 'does not find the epic' do
      post_graphql(epic_query(iid: epic.iid), current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to be_nil
      expect(graphql_data['group']['epic']).to be_nil
    end
  end
end
