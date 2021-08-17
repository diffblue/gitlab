# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting epics information' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    group.add_maintainer(user)
    stub_licensed_features(epics: true)
  end

  context 'when performance_roadmap flag is disabled' do
    let_it_be(:epic1) { create(:epic, group: group, state: 'opened') }
    let_it_be(:epic2) { create(:epic, group: group, state: 'opened') }

    def epics_count
      graphql_data_at(:group, :epics, :nodes).count
    end

    it 'returns epics within timeframe' do
      stub_const('SetsMaxPageSize::DEPRECATED_MAX_PAGE_SIZE', 1)

      post_graphql(epics_query_by_hash(group), current_user: user)
      expect(epics_count).to eq(2)

      stub_feature_flags(performance_roadmap: false)
      post_graphql(epics_query_by_hash(group), current_user: user)
      expect(epics_count).to eq(1)

      stub_feature_flags(performance_roadmap: true)
      post_graphql(epics_query_by_hash(group), current_user: user)
      expect(epics_count).to eq(2)
    end
  end

  describe 'query for epics which start with an iid' do
    let_it_be(:epic1) { create(:epic, group: group, iid: 11) }
    let_it_be(:epic2) { create(:epic, group: group, iid: 22) }
    let_it_be(:epic3) { create(:epic, group: group, iid: 2223) }
    let_it_be(:epic4) { create(:epic, group: group, iid: 29) }

    context 'when a valid iidStartsWith query is provided' do
      it 'returns the expected epics' do
        query_epics_which_start_with_iid('22')

        expect_epics_response(epic2, epic3)
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

  describe 'query for epics by time frame' do
    let_it_be(:epic1) { create(:epic, group: group, state: :opened, start_date: "2019-08-13", end_date: "2019-08-20") }
    let_it_be(:epic2) { create(:epic, group: group, state: :closed, start_date: "2019-08-13", end_date: "2019-08-21") }
    let_it_be(:epic3) { create(:epic, group: group, state: :closed, start_date: "2019-08-22", end_date: "2019-08-26") }
    let_it_be(:epic4) { create(:epic, group: group, state: :closed, start_date: "2019-08-10", end_date: "2019-08-12") }

    context 'when start_date and end_date are present' do
      it 'returns epics within timeframe' do
        post_graphql(epics_query_by_hash(group, 'startDate' => '2019-08-13', 'endDate' => '2019-08-21'), current_user: user)

        expect_epics_response(epic1, epic2)
      end
    end

    context 'when only start_date is present' do
      it 'raises error' do
        post_graphql(epics_query(group, 'startDate', '2019-08-13'), current_user: user)

        expect(graphql_errors).to include(a_hash_including('message' => 'Both startDate and endDate must be present.'))
      end
    end

    context 'when only end_date is present' do
      it 'raises error' do
        post_graphql(epics_query(group, 'endDate', '2019-08-13'), current_user: user)

        expect(graphql_errors).to include(a_hash_including('message' => 'Both startDate and endDate must be present.'))
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

  def epics_query(group, field, value)
    epics_query_by_hash(group, field => value)
  end

  def epics_query_by_hash(group, args = {})
    field_queries = args.map { |key, value| "#{key}:\"#{value}\"" }.join(',')
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

  def expect_epics_response(*epics)
    actual_epics = graphql_data['group']['epics']['nodes'].map { |epic| epic['id'] }
    expected_epics = epics.map { |epic| epic.to_global_id.to_s }

    expect(actual_epics).to contain_exactly(*expected_epics)
    expect(graphql_errors).to be_nil
  end
end
