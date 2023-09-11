# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::InstanceRunnerFailedJobs, :freeze_time, :clean_gitlab_redis_shared_state,
  feature_category: :runner_fleet do
  before do
    stub_licensed_features(runner_performance_insights: runner_performance_insights)
  end

  describe '.track' do
    subject(:track) { described_class.track(job) }

    let_it_be(:instance_runner) { create(:ci_runner, :instance) }

    let(:job) { create(:ci_build, runner: runner) }

    before do
      job.drop!(failure_reason)
    end

    context 'when job fails with runner_system_failure' do
      let(:failure_reason) { :runner_system_failure }

      context 'with runner_performance_insights licensed feature' do
        let(:runner_performance_insights) { true }

        context 'when job is executed in an instance runner' do
          let(:runner) { instance_runner }

          it 'saves job id on redis cache' do
            track

            expect(redis_stored_job_ids).to match_array(formatted_job_ids_for(job))
          end

          context 'when job fails with different failure_reason' do
            let(:failure_reason) { :stuck_or_timeout_failure }

            it 'does not save job' do
              expect { track }.not_to change { redis_stored_job_ids }
            end
          end
        end

        context 'when job is executed in a project runner' do
          let_it_be(:project_runner) { create(:ci_runner, :project) }

          let(:runner) { project_runner }

          it 'does not save job' do
            expect { track }.not_to change { redis_stored_job_ids }
          end
        end
      end

      context 'without runner_performance_insights licensed feature' do
        let(:runner_performance_insights) { false }
        let(:runner) { instance_runner }

        it 'does not save job' do
          expect { track }.not_to change { redis_stored_job_ids }
        end
      end
    end
  end

  describe '.recent_jobs' do
    def recent_jobs
      described_class.recent_jobs(failure_reason: failure_reason)
    end

    subject(:scope) { recent_jobs }

    let_it_be(:runner) { create(:ci_runner, :instance) }
    let_it_be(:job_args) { { runner: runner, failure_reason: :runner_system_failure } }
    let_it_be(:job) { create(:ci_build, created_at: 10.minutes.ago, finished_at: 3.minutes.ago, **job_args) }
    let_it_be(:job2) { create(:ci_build, created_at: 5.minutes.ago, finished_at: 4.minutes.ago, **job_args) }
    let_it_be(:job3) { create(:ci_build, created_at: 5.minutes.ago, finished_at: 5.minutes.ago, **job_args) }

    context 'with runner_performance_insights licensed feature' do
      let(:runner_performance_insights) { true }

      context 'when failure_reason is not runner_system_failure' do
        let(:failure_reason) { :runner_unsupported }

        it 'raises an error' do
          expect { recent_jobs }.to raise_error(
            ArgumentError, 'The only failure reason(s) supported are runner_system_failure'
          )
        end
      end

      context 'when failure_reason is runner_system_failure' do
        let(:failure_reason) { :runner_system_failure }

        context 'when content is not set' do
          it { is_expected.to be_empty }
        end

        context 'when jobs are added' do
          before do
            described_class.track(job)
          end

          it 'returns 3 most recently finished jobs' do
            expect(recent_jobs).to contain_exactly(an_object_having_attributes(id: job.id))

            described_class.track(job2)
            described_class.track(job3)

            expect(recent_jobs).to match([
              an_object_having_attributes(id: job.id),
              an_object_having_attributes(id: job2.id),
              an_object_having_attributes(id: job3.id)
            ])
          end

          context 'when jobs are added in different order' do
            it 'returns 3 most recently finished jobs' do
              expect(recent_jobs).to contain_exactly(an_object_having_attributes(id: job.id))

              described_class.track(job3)
              described_class.track(job2)

              expect(recent_jobs).to match([
                an_object_having_attributes(id: job.id),
                an_object_having_attributes(id: job2.id),
                an_object_having_attributes(id: job3.id)
              ])
            end
          end

          context 'when trimming is required' do
            before do
              stub_const("#{described_class}::JOB_LIMIT", 1)
              stub_const("#{described_class}::JOB_LIMIT_MARGIN", 1)
            end

            it 'returns 2 most recently finished jobs and purges the rest', :aggregate_failures do
              described_class.track(job3)
              described_class.track(job2)

              # Only the last 2 jobs saved will be retained
              expect(redis_stored_job_ids).to eq(formatted_job_ids_for(job2, job3))
              # and of those 2, the most recently finished will be returned (JOB_LIMIT)
              is_expected.to contain_exactly(an_object_having_attributes(id: job2.id))
            end
          end
        end
      end
    end

    context 'without runner_performance_insights licensed feature' do
      let(:runner_performance_insights) { false }

      context 'when failure_reason is runner_system_failure' do
        let(:failure_reason) { :runner_system_failure }

        it { is_expected.to be_empty }
      end
    end
  end

  def redis_stored_job_ids
    Gitlab::Redis::SharedState.with { |redis| redis.lrange(described_class.class.name, 0, -1) }
  end

  def formatted_job_ids_for(*builds)
    builds.map(&:id).map(&:to_s)
  end
end
