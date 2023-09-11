# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.jobs', feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:instance_runner) { create(:ci_runner, :instance) }

  let_it_be(:successful_job) { create(:ci_build, :success, name: 'successful_job') }
  let_it_be(:failed_job) { create(:ci_build, :failed, name: 'failed_job') }
  let_it_be(:pending_job) { create(:ci_build, :pending, name: 'pending_job') }
  let_it_be(:system_failure_job) do
    create(:ci_build, :failed, failure_reason: :runner_system_failure, runner: instance_runner,
      name: 'system_failure_job')
  end

  let(:query_path) do
    [
      [:jobs, query_jobs_args],
      [:nodes]
    ]
  end

  let(:query) do
    wrap_fields(query_graphql_path(query_path, 'id'))
  end

  let(:jobs_graphql_data) { graphql_data_at(:jobs, :nodes) }

  subject(:request) { post_graphql(query, current_user: current_user) }

  context 'when current user is an admin' do
    let_it_be(:current_user) { create(:admin) }

    context "with argument `failure_reason`", feature_category: :runner_fleet do
      let(:query_jobs_args) do
        graphql_args(failure_reason: failure_reason)
      end

      let_it_be(:_system_failure_on_project_runner) do
        project_runner = create(:ci_runner, :project)

        create(:ci_build, :failed, failure_reason: :runner_system_failure, runner: project_runner,
          name: 'system_failure_job2')
      end

      before do
        stub_licensed_features(runner_performance_insights: true)

        Ci::Build.all.each { |build| ::Ci::InstanceRunnerFailedJobs.track(build) }
      end

      context 'as RUNNER_SYSTEM_FAILURE' do
        let(:failure_reason) { :RUNNER_SYSTEM_FAILURE }

        it 'generates an error' do
          request

          expect_graphql_errors_to_include 'failure_reason can only be used together with runner_type: instance_type'
        end

        context 'with argument `runnerTypes`' do
          let(:query_jobs_args) do
            graphql_args(runner_types: runner_types, failure_reason: failure_reason)
          end

          context 'as INSTANCE_TYPE' do
            let(:runner_types) { [:INSTANCE_TYPE] }

            it_behaves_like 'a working graphql query that returns data' do
              before do
                request
              end

              it { expect(jobs_graphql_data).to contain_exactly(a_graphql_entity_for(system_failure_job)) }
            end
          end
        end
      end

      context 'as RUNNER_UNSUPPORTED' do
        let(:failure_reason) { :RUNNER_UNSUPPORTED }

        context 'with argument `runnerTypes`' do
          let(:query_jobs_args) do
            graphql_args(runner_types: runner_types, failure_reason: failure_reason)
          end

          context 'as INSTANCE_TYPE' do
            let(:runner_types) { [:INSTANCE_TYPE] }

            it 'generates an error' do
              request

              expect_graphql_errors_to_include 'failure_reason only supports runner_system_failure'
            end
          end
        end
      end
    end
  end
end
