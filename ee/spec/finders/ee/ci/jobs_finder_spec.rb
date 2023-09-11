# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobsFinder, '#execute', feature_category: :continuous_integration do
  let_it_be(:admin) { create(:user, :admin) }

  let(:params) { {} }

  context 'when project, pipeline, and runner are blank' do
    subject(:finder_execute) { described_class.new(current_user: current_user, params: params).execute }

    context 'when current user is an admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        let_it_be(:instance_runner) { create(:ci_runner, :instance) }
        let_it_be(:group_runner) { create(:ci_runner, :group) }
        let_it_be(:project_runner) { create(:ci_runner, :project) }
        let_it_be(:job_args) { { runner: instance_runner, failure_reason: :runner_system_failure } }
        let_it_be(:job1) { create(:ci_build, :failed, finished_at: 1.minute.ago, **job_args) }
        let_it_be(:job2) { create(:ci_build, :failed, finished_at: 2.minutes.ago, **job_args) }
        let_it_be(:job7) { create(:ci_build, :failed, finished_at: 2.minutes.ago, **job_args) }
        let_it_be(:job3) { create(:ci_build, :failed, finished_at: 2.minutes.ago, runner: group_runner) }
        let_it_be(:job4) { create(:ci_build, :failed, finished_at: 2.minutes.ago, runner: project_runner) }
        let_it_be(:job5) do
          create(:ci_build, :failed, finished_at: 2.minutes.ago, runner: group_runner,
            failure_reason: :runner_system_failure)
        end

        let_it_be(:job6) do
          create(:ci_build, :failed, finished_at: 2.minutes.ago, runner: project_runner,
            failure_reason: :runner_system_failure)
        end

        before do
          stub_licensed_features(runner_performance_insights: runner_performance_insights)

          ::Ci::InstanceRunnerFailedJobs.track(job1)
          ::Ci::InstanceRunnerFailedJobs.track(job2)
        end

        context 'with param `failure_reason` set to :runner_system_failure', :clean_gitlab_redis_shared_state,
          feature_category: :runner_fleet do
          let(:params) { { failure_reason: :runner_system_failure } }

          context 'without runner_performance_insights license' do
            let(:runner_performance_insights) { false }

            it 'raises ArgumentError due to lack of runner_type' do
              expect(::Ci::Build).not_to receive(:recently_failed_on_instance_runner)

              expect { finder_execute }.to raise_error(
                ArgumentError, 'failure_reason can only be used together with runner_type: instance_type'
              )
            end

            context 'with param :runner_type set to [instance_type]' do
              let(:params) { { failure_reason: :runner_system_failure, runner_type: %w[instance_type] } }

              it 'returns no jobs due to lack of license' do
                expect(::Ci::Build).to receive(:recently_failed_on_instance_runner)
                  .with(:runner_system_failure).once.and_call_original

                expect(finder_execute.ids).to be_empty
              end
            end
          end

          context 'with runner_performance_insights license' do
            let(:runner_performance_insights) { true }

            context 'with param :runner_type set to [instance_type]' do
              let(:params) { { failure_reason: :runner_system_failure, runner_type: %w[instance_type] } }

              it 'returns builds tracked by InstanceRunnerFailedJobs' do
                expect(::Ci::Build).to receive(:recently_failed_on_instance_runner)
                  .with(:runner_system_failure).once.and_call_original

                expect(finder_execute.ids).to contain_exactly(job1.id, job2.id)
              end
            end

            context 'with param :runner_type set to multiple runner types', :aggregate_failures do
              let(:params) { { failure_reason: :runner_system_failure, runner_type: %w[instance_type group_type] } }

              it 'raises ArgumentError due to multiple runner types' do
                expect(::Ci::Build).not_to receive(:recently_failed_on_instance_runner)

                expect { finder_execute }.to raise_error(
                  ArgumentError, 'failure_reason can only be used together with runner_type: instance_type'
                )
              end

              context 'with feature flag :admin_jobs_filter_runner_type disabled' do
                before do
                  stub_feature_flags(admin_jobs_filter_runner_type: false)
                end

                it 'raises ArgumentError due to multiple runner types' do
                  expect(::Ci::Build).not_to receive(:recently_failed_on_instance_runner)

                  expect { finder_execute }.to raise_error(
                    ArgumentError, 'failure_reason can only be used together with runner_type: instance_type'
                  )
                end
              end
            end
          end
        end

        context 'with param `failure_reason` not set to :runner_system_failure', :clean_gitlab_redis_shared_state,
          feature_category: :runner_fleet do
          let(:params) { { failure_reason: :runner_unsupported } }

          context 'with runner_performance_insights license' do
            let(:runner_performance_insights) { true }

            context 'with param :runner_type set to [instance_type]' do
              let(:params) { { failure_reason: :runner_unsupported, runner_type: %w[instance_type] } }

              it 'raises ArgumentError due to unsupported failure_reason' do
                expect(::Ci::Build).not_to receive(:recently_failed_on_instance_runner)

                expect { finder_execute }
                  .to raise_error(ArgumentError, 'failure_reason only supports runner_system_failure')
              end
            end
          end
        end
      end
    end
  end
end
