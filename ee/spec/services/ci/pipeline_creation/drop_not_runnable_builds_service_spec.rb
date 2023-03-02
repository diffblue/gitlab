# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineCreation::DropNotRunnableBuildsService, feature_category: :continuous_integration do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let_it_be_with_reload(:pipeline) do
    create(:ci_pipeline, project: project, status: :created)
  end

  let_it_be_with_reload(:job) do
    create(:ci_build, project: pipeline.project, pipeline: pipeline)
  end

  let_it_be_with_reload(:job_with_tags) do
    create(:ci_build, :tags, project: pipeline.project, pipeline: pipeline)
  end

  let_it_be(:instance_runner) do
    create(:ci_runner,
      :online,
      runner_type: :instance_type,
      public_projects_minutes_cost_factor: 0,
      private_projects_minutes_cost_factor: 1)
  end

  describe '#execute' do
    subject(:execute) { described_class.new(pipeline).execute }

    shared_examples 'jobs allowed to run' do
      it 'does not drop the jobs' do
        expect { execute }
          .to not_change { job.reload.status }
          .and not_change { job_with_tags.reload.status }
      end
    end

    shared_examples 'quota exceeded' do
      before do
        allow(pipeline.project).to receive(:ci_minutes_usage)
          .and_return(double('usage', minutes_used_up?: true, quota_enabled?: true))
      end

      it 'drops the job with ci_quota_exceeded reason' do
        execute
        [job, job_with_tags].each(&:reload)

        expect(job).to be_failed
        expect(job.failure_reason).to eq('ci_quota_exceeded')

        expect(job_with_tags).to be_pending
      end

      context 'when shared runners are disabled' do
        before do
          pipeline.project.update!(shared_runners_enabled: false)
        end

        it_behaves_like 'jobs allowed to run'
      end

      context 'with project runners' do
        let_it_be(:project_runner) do
          create(:ci_runner, :online, runner_type: :project_type, projects: [project])
        end

        it_behaves_like 'jobs allowed to run'
      end

      context 'with group runners' do
        let_it_be(:group_runner) do
          create(:ci_runner, :online, runner_type: :group_type, groups: [group])
        end

        it_behaves_like 'jobs allowed to run'
      end

      context 'when the pipeline status is running' do
        before do
          pipeline.update!(status: :running)
        end

        it_behaves_like 'jobs allowed to run'
      end
    end

    context 'with public projects' do
      before do
        pipeline.project.update!(visibility_level: ::Gitlab::VisibilityLevel::PUBLIC)
      end

      it_behaves_like 'jobs allowed to run'

      context 'when the CI quota is exceeded' do
        before do
          allow(pipeline.project).to receive(:ci_minutes_usage)
            .and_return(double('usage', minutes_used_up?: true, quota_enabled?: true))
        end

        it_behaves_like 'jobs allowed to run'
      end
    end

    context 'with internal projects' do
      before do
        pipeline.project.update!(visibility_level: ::Gitlab::VisibilityLevel::INTERNAL)
      end

      it_behaves_like 'jobs allowed to run'
      it_behaves_like 'quota exceeded'
    end

    context 'with private projects' do
      before do
        pipeline.project.update!(visibility_level: ::Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'jobs allowed to run'
      it_behaves_like 'quota exceeded'
    end
  end
end
