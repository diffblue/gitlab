# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciMinutesUsage' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, name: 'Project 1', namespace: user.namespace) }

  before(:all) do
    create(:ci_namespace_monthly_usage, namespace: user.namespace, amount_used: 50, date: Date.new(2021, 5, 1))
    create(:ci_project_monthly_usage, project: project, amount_used: 50, date: Date.new(2021, 5, 1))
  end

  it 'returns usage data by month for the current user' do
    query = <<-QUERY
      {
        ciMinutesUsage {
          nodes {
            minutes
            month
            projects {
              nodes {
                name
                minutes
              }
            }
          }
        }
      }
    QUERY

    post_graphql(query, current_user: user)

    monthly_usage = graphql_data_at(:ci_minutes_usage, :nodes)
    expect(monthly_usage).to contain_exactly({
      'month' => 'May',
      'minutes' => 50,
      'projects' => { 'nodes' => [{
        'name' => 'Project 1',
        'minutes' => 50
      }] }
    })
  end

  it 'does not create N+1 queries' do
    query = <<-QUERY
      {
        ciMinutesUsage {
          nodes {
            projects {
              nodes {
                name
              }
            }
          }
        }
      }
    QUERY

    control_count = ActiveRecord::QueryRecorder.new do
      post_graphql(query, current_user: user)
    end
    expect(graphql_errors).to be_nil

    project_2 = create(:project, name: 'Project 2', namespace: user.namespace)
    create(:ci_project_monthly_usage, project: project_2, amount_used: 50, date: Date.new(2021, 5, 1))

    expect do
      post_graphql(query, current_user: user)
    end.not_to exceed_query_limit(control_count)
    expect(graphql_errors).to be_nil
  end
end
