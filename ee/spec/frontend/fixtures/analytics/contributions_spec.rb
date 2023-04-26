# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Contribution Analytics (GraphQL fixtures)', feature_category: :value_stream_management do
  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers
    include JavaScriptFixturesHelpers

    let_it_be(:user_1) { create(:user, name: 'Aaron') }
    let_it_be(:user_2) { create(:user,  name: 'Bob') }
    let_it_be(:user_3) { create(:user,  name: 'Carl') }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    before do
      stub_licensed_features(contribution_analytics: true)

      group.add_owner(user_1)
      group.add_maintainer(user_2)
      group.add_developer(user_3)

      travel_to(Date.parse('2023-03-15'))
      create_contributions(user_1, 1)
      create_contributions(user_2, 2)
      create_contributions(user_3, 3)
      travel_back
    end

    contributions_query_path = 'analytics/contribution_analytics/graphql/contributions.query.graphql'

    it "graphql/#{contributions_query_path}.json" do
      query = get_graphql_query_as_string(contributions_query_path, ee: true)

      post_graphql(query, current_user: user_1,
        variables: { fullPath: group.full_path, startDate: '2023-03-12', endDate: '2023-04-12' })

      expect_graphql_errors_to_be_empty
    end
  end

  private

  def create_contributions(member, event_count)
    create_list(:event, event_count, :pushed, project: project, author: member)

    create_list(:event, event_count, :created, :for_issue, project: project, author: member)
    create_list(:event, event_count, :closed, :for_issue, project: project, author: member)

    create_list(:event, event_count, :created, :for_merge_request, project: project, author: member)
    create_list(:event, event_count, :closed, :for_merge_request, project: project, author: member)
    create_list(:event, event_count, :merged, :for_merge_request, project: project, author: member)
    create_list(:event, event_count, :approved, :for_merge_request, project: project, author: member)
  end
end
