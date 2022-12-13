# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciMinutesUsage', feature_category: :purchase do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:user_project) { create(:project, name: 'Project 1', namespace: user.namespace) }
  let_it_be_with_refind(:group) { create(:group, :public, name: 'test') }

  before(:all) do
    create(:ci_namespace_monthly_usage,
      namespace: user.namespace,
      amount_used: 50,
      shared_runners_duration: 100,
      date: Date.new(2021, 5, 1))

    create(:ci_project_monthly_usage,
      project: user_project,
      amount_used: 40,
      shared_runners_duration: 80,
      date: Date.new(2021, 5, 1))

    create(:ci_namespace_monthly_usage,
      namespace: group,
      amount_used: 100,
      shared_runners_duration: 200,
      date: Date.new(2021, 6, 1))
  end

  subject(:result) { post_graphql(query, current_user: user) }

  context 'when no namespace_id is provided' do
    let(:query) do
      <<-QUERY
        {
          ciMinutesUsage {
            nodes {
              minutes
              sharedRunnersDuration
              month
              projects {
                nodes {
                  minutes
                  sharedRunnersDuration
                  project {
                    name
                  }
                }
              }
            }
          }
        }
      QUERY
    end

    it 'returns usage data by month for the current user' do
      subject

      monthly_usage = graphql_data_at(:ci_minutes_usage, :nodes)
      expect(monthly_usage).to contain_exactly({
        'month' => 'May',
        'minutes' => 50,
        'sharedRunnersDuration' => 100,
        'projects' => { 'nodes' => [{
          'minutes' => 40,
          'sharedRunnersDuration' => 80,
          'project' => {
            'name' => 'Project 1'
          }
        }] }
      })
    end

    it 'does not create N+1 queries' do
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

  context 'when namespace_id is provided' do
    let(:namespace) { group }

    let(:query) do
      <<-QUERY
        {
          ciMinutesUsage(namespaceId: "#{namespace.to_global_id}") {
            nodes {
              minutes
              sharedRunnersDuration
              month
            }
          }
        }
      QUERY
    end

    context 'when group is root' do
      context 'when user is an owner' do
        before do
          group.add_owner(user)
        end

        it 'returns the usage data' do
          subject

          monthly_usage = graphql_data_at(:ci_minutes_usage, :nodes)
          expect(monthly_usage).to contain_exactly({
            'month' => 'June',
            'minutes' => 100,
            'sharedRunnersDuration' => 200
          })
        end
      end

      context 'when user is not an owner' do
        before do
          group.add_developer(user)
        end

        it 'does not return usage data' do
          subject

          monthly_usage = graphql_data_at(:ci_minutes_usage, :nodes)
          expect(monthly_usage).to be_empty
        end
      end
    end

    context 'when group is a subgroup' do
      let(:subgroup) { create(:group, :public, parent: group) }
      let(:namespace) { subgroup }

      before do
        create(:ci_namespace_monthly_usage, namespace: subgroup)
        subgroup.add_owner(user)
      end

      it 'does not return usage data' do
        subject

        monthly_usage = graphql_data_at(:ci_minutes_usage, :nodes)
        expect(monthly_usage).to be_empty
      end
    end
  end
end
