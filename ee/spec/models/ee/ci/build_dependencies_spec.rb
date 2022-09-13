# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildDependencies do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, refind: true) { create(:project, :repository) }

  let(:dependencies) {}

  let(:pipeline) do
    create(:ci_pipeline,
      project: project,
      sha: project.commit.id,
      ref: project.default_branch,
      status: 'success')
  end

  let(:pipeline2) do
    create(:ci_pipeline,
      project: project,
      sha: project.commit.id,
      ref: project.default_branch,
      status: 'success')
  end

  let(:deploy_stage) { create(:ci_stage, pipeline: pipeline, name: 'deploy') }

  let!(:job) do
    create(:ci_build,
      pipeline: pipeline,
      name: 'final',
      stage_idx: 3,
      ci_stage: deploy_stage,
      user: user,
      options: { cross_dependencies: dependencies })
  end

  before do
    project.add_developer(user)
    pipeline.update!(user: user)
    stub_licensed_features(cross_project_pipelines: true)
  end

  context 'for cross_project dependencies' do
    subject { described_class.new(job).all }

    context 'when cross_dependencies are not defined' do
      it { is_expected.to be_empty }
    end

    context 'with missing dependency' do
      let(:dependencies) do
        [
          {
            project: 'some/project',
            job: 'some/job',
            ref: 'some/ref',
            artifacts: true
          }
        ]
      end

      it { is_expected.to be_empty }
    end

    context 'with cross_dependencies to the same project' do
      let(:build_stage) { create(:ci_stage, pipeline: pipeline2, name: 'build') }

      let!(:dependency) do
        create(:ci_build, :success,
          pipeline: pipeline2,
          name: 'dependency',
          stage_idx: 1,
          ci_stage: build_stage,
          user: user
        )
      end

      let(:dependencies) do
        [
          {
            project: project.full_path,
            job: 'dependency',
            ref: pipeline2.ref,
            artifacts: artifacts
          }
        ]
      end

      context 'with artifacts true' do
        let(:artifacts) { true }

        it { is_expected.to contain_exactly(dependency) }
      end

      context 'with artifacts false' do
        let(:artifacts) { false }

        it { is_expected.to be_empty }
      end

      context 'with dependency names from environment variables' do
        before do
          job.yaml_variables.push(key: 'DEPENDENCY_NAME', value: 'dependency', public: true)
          job.save!
        end

        let(:dependencies) do
          [
            {
              project: '$CI_PROJECT_PATH',
              job: '$DEPENDENCY_NAME',
              ref: '$CI_COMMIT_BRANCH',
              artifacts: true
            }
          ]
        end

        it { is_expected.to contain_exactly(dependency) }
      end
    end

    context 'with cross_dependencies to another ref in same project' do
      let(:another_pipeline) do
        create(:ci_pipeline,
          project: project,
          sha: project.commit.id,
          ref: 'feature',
          status: 'success')
      end

      let(:dependencies) do
        [
          {
            project: project.full_path,
            job: 'dependency',
            ref: another_pipeline.ref,
            artifacts: true
          }
        ]
      end

      let(:deploy_stage) { create(:ci_stage, pipeline: another_pipeline, name: 'deploy') }

      let!(:dependency) do
        create(:ci_build, :success,
          pipeline: another_pipeline,
          ref: another_pipeline.ref,
          name: 'dependency',
          stage_idx: 4,
          ci_stage: deploy_stage,
          user: user
        )
      end

      it { is_expected.to contain_exactly(dependency) }
    end

    context 'with cross_dependencies to a pipeline in another project' do
      let(:other_project) { create(:project, :repository) }

      let(:other_pipeline) do
        create(:ci_pipeline,
          project: other_project,
          sha: other_project.commit.id,
          ref: other_project.default_branch,
          status: 'success',
          user: user)
      end

      let(:feature_pipeline) do
        create(:ci_pipeline,
          project: project,
          sha: project.commit.id,
          ref: 'feature',
          status: 'success')
      end

      let(:dependencies) do
        [
          {
            project: other_project.full_path,
            job: 'other_dependency',
            ref: other_pipeline.ref,
            artifacts: true
          },
          {
            project: project.full_path,
            job: 'dependency',
            ref: feature_pipeline.ref,
            artifacts: true
          }
        ]
      end

      let(:deploy_stage) { create(:ci_stage, pipeline: other_pipeline, name: 'deploy') }

      let!(:other_dependency) do
        create(:ci_build, :success,
          pipeline: other_pipeline,
          ref: other_pipeline.ref,
          name: 'other_dependency',
          stage_idx: 4,
          ci_stage: deploy_stage,
          user: user)
      end

      let(:feature_deploy_stage) { create(:ci_stage, pipeline: feature_pipeline, name: 'deploy') }

      let!(:dependency) do
        create(:ci_build, :success,
          pipeline: feature_pipeline,
          ref: feature_pipeline.ref,
          name: 'dependency',
          stage_idx: 4,
          ci_stage: feature_deploy_stage,
          user: user)
      end

      context 'with permissions to other_project' do
        before do
          other_project.add_developer(user)
        end

        it 'contains both dependencies' do
          is_expected.to contain_exactly(dependency, other_dependency)
        end

        context 'when license does not have cross_project_pipelines' do
          before do
            stub_licensed_features(cross_project_pipelines: false)
          end

          it { expect(subject).to be_empty }
        end
      end

      context 'without permissions to other_project' do
        it { is_expected.to contain_exactly(dependency) }
      end
    end

    context 'with too many cross_dependencies' do
      let(:cross_dependencies_limit) do
        ::Gitlab::Ci::Config::Entry::Needs::NEEDS_CROSS_PROJECT_DEPENDENCIES_LIMIT
      end

      let(:build_stage) { create(:ci_stage, pipeline: pipeline2, name: 'build') }

      before do
        cross_dependencies_limit.next.times do |index|
          create(:ci_build, :success,
            pipeline: pipeline2, name: "dependency-#{index}",
            stage_idx: 1, ci_stage: build_stage, user: user
          )
        end
      end

      let(:dependencies) do
        Array.new(cross_dependencies_limit.next) do |index|
          {
            project: project.full_path,
            job: "dependency-#{index}",
            ref: pipeline2.ref,
            artifacts: true
          }
        end
      end

      it 'returns a limited number of dependencies' do
        expect(subject.size).to eq(cross_dependencies_limit)
      end
    end
  end

  describe '#all' do
    let(:build_dependencies) { described_class.new(job) }

    subject { build_dependencies.all }

    context 'with both cross project and cross pipeline dependencies' do
      let(:other_project) { create(:project, :repository) }
      let(:build_stage) { create(:ci_stage, pipeline: upstream_pipeline, name: 'build') }
      let(:deploy_stage) { create(:ci_stage, pipeline: other_project_pipeline, name: 'deploy') }

      let(:other_project_pipeline) do
        create(:ci_pipeline,
          project: other_project,
          sha: other_project.commit.id,
          ref: other_project.default_branch,
          status: 'success',
          user: user)
      end

      let!(:cross_project_dependency) do
        create(:ci_build, :success,
          pipeline: other_project_pipeline,
          ref: other_project_pipeline.ref,
          name: 'deploy',
          stage_idx: 4,
          ci_stage: deploy_stage,
          user: user)
      end

      let(:upstream_pipeline) do
        create(:ci_pipeline,
          project: project,
          sha: project.commit.id,
          ref: project.default_branch,
          status: 'success',
          user: user)
      end

      let!(:upstream_pipeline_dependency) do
        create(:ci_build, :success,
          pipeline: upstream_pipeline,
          ref: upstream_pipeline.ref,
          name: 'build',
          stage_idx: 1,
          ci_stage: build_stage,
          user: user)
      end

      let(:pipeline) do
        create(:ci_pipeline,
          child_of: upstream_pipeline,
          project: project,
          sha: project.commit.id,
          ref: project.default_branch,
          status: 'success')
      end

      let(:dependencies) do
        [
          { pipeline: '$UPSTREAM_PIPELINE_ID', job: '$UPSTREAM_JOB', artifacts: true },
          { project: other_project.full_path, ref: other_project.default_branch, job: 'deploy', artifacts: true }
        ]
      end

      before do
        job.yaml_variables.push(key: 'UPSTREAM_PIPELINE_ID', value: upstream_pipeline.id.to_s, public: true)
        job.yaml_variables.push(key: 'UPSTREAM_JOB', value: upstream_pipeline_dependency.name, public: true)
        job.save!

        other_project.add_developer(user)
      end

      it 'returns both dependencies' do
        is_expected.to contain_exactly(cross_project_dependency, upstream_pipeline_dependency)
      end
    end
  end
end
