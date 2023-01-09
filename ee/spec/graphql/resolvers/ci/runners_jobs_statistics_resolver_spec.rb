# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::RunnersJobsStatisticsResolver, feature_category: :runner_fleet do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:project_runner1) { create(:ci_runner, :project, projects: [project]) }
  let_it_be(:project_runner2) { create(:ci_runner, :project, projects: [project]) }
  let_it_be(:pipeline1) { create(:ci_pipeline, project: project) }
  let_it_be(:pipeline2) { create(:ci_pipeline, project: project) }

  before_all do
    freeze_time do
      create(:ci_build, :running, runner: project_runner1, pipeline: pipeline1,
             queued_at: 5.seconds.ago, started_at: 1.second.ago)
      create(:ci_build, :success, runner: project_runner2, pipeline: pipeline2,
             queued_at: 10.seconds.ago, started_at: 8.seconds.ago, finished_at: 7.seconds.ago)
      create(:ci_build, :success, runner: project_runner1, pipeline: pipeline2,
             queued_at: 10.seconds.ago, started_at: 9.seconds.ago, finished_at: 1.second.ago)
      create(:ci_build, :failed, runner: project_runner2, pipeline: pipeline1, queued_at: 2.minutes.ago,
             started_at: nil)
      create(:ci_build, :success, runner: project_runner2, pipeline: pipeline1,
             queued_at: 10.seconds.ago, started_at: 9.5.seconds.ago, finished_at: 1.second.ago)
    end
  end

  describe '#resolve' do
    subject(:response) do
      resolve(described_class,
              obj: obj,
              ctx: { current_user: current_user },
              lookahead: positive_lookahead,
              arg_style: :internal)
    end

    let(:obj) { instance_double(::Gitlab::Graphql::Pagination::Keyset::Connection, items: ::Ci::Runner.project_type) }

    context 'with admin', :enable_admin_mode do
      let_it_be(:current_user) { create(:admin) }

      context 'when licensed' do
        before do
          stub_licensed_features(runner_jobs_statistics: true)
        end

        context 'with no builds' do
          let(:obj) do
            instance_double(::Gitlab::Graphql::Pagination::Keyset::Connection, items: ::Ci::Runner.instance_type)
          end

          it 'retrieves expected fields with nil values' do
            expect(response.object).not_to be_nil
            expect(response.object).to match a_hash_including(
              queued_duration: {
                p50: nil,
                p75: nil,
                p90: nil,
                p95: nil,
                p99: nil
              }
            )
          end
        end

        context 'with builds' do
          let(:expected_job_statistics) do
            # expected percentiles are calculated by taking the `started_at - queued_at` values for the jobs
            # executed by all project runners and using PostgreSQL's PERCENTILE_CONT function.
            a_hash_including(
              queued_duration: {
                p50: 1.5.seconds,
                p75: 2.5.seconds,
                p90: 3.4.seconds,
                p95: 3.7.seconds,
                p99: 3.94.seconds
              }
            )
          end

          it 'returns jobs statistics' do
            expect(response).to be_an_instance_of(Types::Ci::JobsStatisticsType)
            expect(response.object).to match(expected_job_statistics)
          end

          context 'with JOBS_LIMIT set to one lower than dataset size' do
            before do
              stub_const('Resolvers::Ci::RunnersJobsStatisticsResolver::JOBS_LIMIT',
                         ::Ci::Build.where.not(started_at: nil).count)
            end

            it 'ignores non-started job and does not affect statistics' do
              expect(response.object).to match(expected_job_statistics)
            end
          end

          context 'with RUNNERS_LIMIT set to one' do
            before do
              stub_const('Resolvers::Ci::RunnersJobsStatisticsResolver::RUNNERS_LIMIT', 1)
            end

            it 'returns statistics from latest runner' do
              # expected percentiles are calculated by taking the `started_at - queued_at` values for the jobs
              # executed by the first runner (`project_runner1`) and using PostgreSQL's PERCENTILE_CONT function.
              expect(response.object).to match(a_hash_including(
                queued_duration: {
                  p50: 1.25.seconds,
                  p75: 1.625.seconds,
                  p90: 1.85.seconds,
                  p95: 1.925.seconds,
                  p99: 1.985.seconds
                }
              ))
            end
          end
        end
      end

      context 'when not licensed' do
        before do
          stub_licensed_features(runner_jobs_statistics: false)
        end

        context 'when all fields are requested' do
          specify { expect(response).to be_nil }
        end
      end
    end

    context 'with regular user' do
      let_it_be(:current_user) { create(:user) }

      context 'when licensed' do
        before do
          stub_licensed_features(runner_jobs_statistics: true)
        end

        context 'when all fields are requested' do
          specify { expect(response).to be_nil }
        end
      end
    end
  end
end
