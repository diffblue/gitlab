# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting epics information', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:node_path) { %w[group epics nodes] }

  before do
    group.add_maintainer(user)
    stub_licensed_features(epics: true)
  end

  describe 'query for epics which start with an iid' do
    let_it_be(:epic1) { create(:epic, group: group, iid: 11) }
    let_it_be(:epic2) { create(:epic, group: group, iid: 22) }
    let_it_be(:epic3) { create(:epic, group: group, iid: 2223) }
    let_it_be(:epic4) { create(:epic, group: group, iid: 29) }

    context 'when a valid iidStartsWith query is provided' do
      it 'returns the expected epics' do
        query_epics_which_start_with_iid('22')

        expect_epics_response([epic2, epic3], node_path: node_path)
      end
    end

    context 'when invalid iidStartsWith query is provided' do
      it 'fails with negative number' do
        query_epics_which_start_with_iid('-2')

        expect(graphql_errors).to include(a_hash_including('message' => 'Invalid `iidStartsWith` query'))
      end

      it 'fails with string' do
        query_epics_which_start_with_iid('foo')

        expect(graphql_errors).to include(a_hash_including('message' => 'Invalid `iidStartsWith` query'))
      end

      it 'fails if query contains line breaks' do
        query_epics_which_start_with_iid('2\nfoo')

        expect(graphql_errors).to include(a_hash_including('message' => 'Invalid `iidStartsWith` query'))
      end
    end

    def query_epics_which_start_with_iid(iid)
      post_graphql(epics_query(group, 'iidStartsWith', iid), current_user: user)
    end
  end

  describe 'query for epics by created_at and updated_at' do
    let_it_be(:epic1) { create(:epic, group: group, created_at: 2.weeks.ago, updated_at: 10.seconds.ago) }
    let_it_be(:epic2) { create(:epic, group: group, created_at: 8.days.ago, updated_at: 2.minutes.ago) }
    let_it_be(:epic3) { create(:epic, group: group, created_at: 2.hours.ago, updated_at: 9.minutes.ago) }
    let_it_be(:epic4) { create(:epic, group: group, created_at: 15.minutes.ago, updated_at: 14.minutes.ago) }

    it 'filters by createdBefore' do
      post_graphql(epics_query(group, 'createdBefore', 5.days.ago), current_user: user)

      expect_epics_response([epic1, epic2], node_path: node_path)
    end

    it 'filters by createdAfter' do
      post_graphql(epics_query(group, 'createdAfter', 5.days.ago), current_user: user)

      expect_epics_response([epic3, epic4], node_path: node_path)
    end

    it 'filters by updatedBefore' do
      post_graphql(epics_query(group, 'updatedBefore', 7.minutes.ago), current_user: user)

      expect_epics_response([epic3, epic4], node_path: node_path)
    end

    it 'filters by updatedAfter' do
      post_graphql(epics_query(group, 'updatedAfter', 7.minutes.ago), current_user: user)

      expect_epics_response([epic1, epic2], node_path: node_path)
    end

    it 'filters by a combination of created parameters provided' do
      post_graphql(epics_query_by_hash(group, { 'createdBefore' => Time.zone.now, 'createdAfter' => 20.minutes.ago }), current_user: user)

      expect_epics_response([epic4], node_path: node_path)
    end

    it 'filters by a combination of created/updated parameters provided' do
      post_graphql(epics_query_by_hash(group, { 'updatedBefore' => 3.minutes.ago, 'createdAfter' => 20.minutes.ago }), current_user: user)

      expect_epics_response([epic4], node_path: node_path)
    end

    it 'returns nothing for impossible parameters' do
      post_graphql(epics_query_by_hash(group, { 'createdBefore' => 7.minutes.ago, 'createdAfter' => Time.zone.now }), current_user: user)

      expect_epics_response([], node_path: node_path) # empty set
    end
  end

  describe 'query for epics by time frame' do
    let_it_be(:epic1) { create(:epic, group: group, state: :opened, start_date: "2019-08-13", end_date: "2019-08-20") }
    let_it_be(:epic2) { create(:epic, group: group, state: :closed, start_date: "2019-08-13", end_date: "2019-08-21") }
    let_it_be(:epic3) { create(:epic, group: group, state: :closed, start_date: "2019-08-22", end_date: "2019-08-26") }
    let_it_be(:epic4) { create(:epic, group: group, state: :closed, start_date: "2019-08-10", end_date: "2019-08-12") }

    context "when `start` and `end` are present" do
      it 'returns epics within timeframe' do
        post_graphql(epics_query_by_hash(group, "timeframe: {#{field_query({ 'start' => '2019-08-13', 'end' => '2019-08-21' })}}"), current_user: user)

        expect_epics_response([epic1, epic2], node_path: node_path)
      end
    end

    context 'when only start is present' do
      it 'raises error' do
        post_graphql(epics_query_by_hash(group, "timeframe: {#{field_query({ 'start' => '2019-08-13' })}}"), current_user: user)

        expect(graphql_errors).to include(a_hash_including('message' => "Argument 'end' on InputObject 'Timeframe' is required. Expected type Date!"))
      end
    end

    context 'when only end is present' do
      it 'raises error' do
        post_graphql(epics_query_by_hash(group, "timeframe: {#{field_query({ 'end' => '2019-08-21' })}}"), current_user: user)

        expect(graphql_errors).to include(a_hash_including('message' => "Argument 'start' on InputObject 'Timeframe' is required. Expected type Date!"))
      end
    end
  end

  context 'query for epics with events' do
    let_it_be(:epic) { create(:epic, group: group) }

    it 'can lookahead to prevent N+1 queries' do
      create_list(:event, 10, :created, target: epic, group: group)

      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        query_epics_with_events(1)
      end.count

      events = graphql_dig_at(graphql_data, :group, :epics, :nodes, :events, :nodes)
      expect(events.count).to eq(1)

      expect do
        query_epics_with_events(10)
      end.not_to exceed_all_query_limit(control_count)

      data = graphql_data(fresh_response_data)
      events = graphql_dig_at(data, :group, :epics, :nodes, :events, :nodes)
      expect(events.count).to eq(10)
    end
  end

  context 'query for epics with ancestors' do
    let_it_be(:cross_group) { create(:group, :private) }
    let_it_be(:parent_epic1) { create(:epic, group: group) }
    let_it_be(:parent_epic2) { create(:epic, parent: parent_epic1, group: cross_group) }
    let_it_be(:parent_epic3) { create(:epic, group: group, parent: parent_epic2) }
    let_it_be(:epic) { create(:epic, group: group, parent: parent_epic3) }

    let(:node_path) { %w[group epic ancestors nodes] }

    it 'returns only ancestors up to the last accessible ancestor' do
      query_epic_with_ancestors(epic.iid)

      expect_epics_response([parent_epic3], node_path: node_path)
    end

    context 'when user is member of cross-hierarchy group' do
      before do
        parent_epic2.group.add_developer(user)
      end

      it 'returns all ancestors' do
        query_epic_with_ancestors(epic.iid)

        expect_epics_response([parent_epic1, parent_epic2, parent_epic3], node_path: node_path)
      end
    end
  end

  context 'when requesting awardEmoji' do
    let_it_be(:epic) { create(:epic, group: group) }
    let_it_be(:award_emoji) { create(:award_emoji, awardable: epic, user: user) }
    let_it_be(:query) do
      <<-GQL
      query {
        group(fullPath: "#{group.full_path}") {
          epic(iid: #{epic.iid}) {
            awardEmoji {
              nodes {
                user {
                  username
                }
                name
              }
            }
          }
        }
      }
      GQL
    end

    it 'includes award emojis' do
      post_graphql(query, current_user: user)

      response = graphql_data_at(:group, :epic, :award_emoji, :nodes)

      expect(response.length).to eq(1)
      expect(response.first['user']['username']).to eq(user.username)
      expect(response.first['name']).to eq(award_emoji.name)
    end
  end

  describe 'N+1 query checks' do
    let_it_be(:epic_a) { create(:epic, group: group) }
    let_it_be(:epic_b) { create(:epic, group: group) }

    let(:extra_iid_for_second_query) { epic_b.iid.to_s }
    let(:search_params) { { iids: [epic_a.iid.to_s] } }

    def execute_query
      query = graphql_query_for(
        :group,
        { full_path: group.full_path },
        query_graphql_field(
          :epics, search_params,
          query_graphql_field(:nodes, nil, requested_fields)
        )
      )
      post_graphql(query, current_user: user)
    end

    context 'when requesting `award_emoji`' do
      let(:requested_fields) { 'awardEmoji { nodes { name } }' }

      before do
        create(:award_emoji, awardable: epic_a, user: user)
        create(:award_emoji, awardable: epic_b, user: user)
      end

      include_examples 'N+1 query check'

      it 'N+1 query test contains data' do
        execute_query

        response = graphql_data_at(:group, :epics, :nodes).flat_map { |node| node['awardEmoji']['nodes'] }

        expect(response).not_to be_empty
      end
    end

    context 'when requesting `health_status`' do
      let(:requested_fields) { 'healthStatus { issuesAtRisk issuesNeedingAttention issuesOnTrack }' }

      before do
        # Add children to epic_a
        create(:epic, group: group, title: 'child epic 1', parent: epic_a)
        create(:epic, group: group, title: 'child epic 2', parent: epic_a)
        # Add children to epic_b
        create(:epic, group: group, title: 'child epic 3', parent: epic_b)
        create(:epic, group: group, title: 'child epic 4', parent: epic_b)
      end

      include_examples 'N+1 query check'
    end
  end

  describe 'query for epics including their count' do
    let(:query) do
      <<~QUERY
        query groupEpics($groupPath: ID!, $firstPageSize: Int) {
          group(fullPath: $groupPath) {
            id
            epics(
              first: $firstPageSize
            ) {
              count
              nodes {
                id
                iid
              }
            }
          }
        }
      QUERY
    end

    before do
      create_list(:epic, 10, group: group)
    end

    it 'returns epics total count' do
      page_size = 5

      post_graphql(
        query,
        current_user: user,
        variables: {
          groupPath: group.full_path,
          firstPageSize: page_size
        }
      )

      epics = graphql_dig_at(graphql_data, :group, :epics)
      expect(epics['nodes'].size).to eq(page_size)
      expect(epics['count']).to eq(10)
    end
  end

  def query_epics_with_events(number)
    epics_field = <<~NODE
      epics {
        nodes {
          id
          events(first: #{number}) {
            nodes {
              id
            }
          }
        }
      }
    NODE

    post_graphql(
      graphql_query_for('group', { 'fullPath' => group.full_path }, epics_field),
      current_user: user
    )
  end

  def query_epic_with_ancestors(epic_iid)
    epics_field = <<~NODE
      epic(iid: #{epic_iid}) {
        id
        ancestors {
          nodes {
            id
          }
        }
      }
    NODE

    post_graphql(
      graphql_query_for('group', { 'fullPath' => group.full_path }, epics_field),
      current_user: user
    )
  end

  def epics_query(group, field, value)
    epics_query_by_hash(group, field_query({ field => value }))
  end

  def epics_query_by_hash(group, args = {})
    field_queries = field_query(args)
    field_queries = " ( #{field_queries} ) " if field_queries.present?

    <<~QUERY
      query {
        group(fullPath: "#{group.full_path}") {
          id,
          epics#{field_queries} {
            nodes {
              id
            }
          }
        }
      }
    QUERY
  end

  def field_query(args)
    return args if args.is_a?(String)

    args.map do |key, value|
      "#{key}:" + (value.is_a?(Hash) ? field_query(value) : "\"#{value}\"")
    end.join(',')
  end

  def expect_epics_response(epics, node_path:)
    epics ||= []
    nodes = graphql_data.dig(*node_path)
    actual_epics = nodes.map { |epic| epic['id'] }
    expected_epics = epics.map { |epic| epic.to_global_id.to_s }

    expect(actual_epics).to contain_exactly(*expected_epics)
    expect(graphql_errors).to be_nil
  end
end
