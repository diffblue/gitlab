# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService do
  subject(:execute) { service.execute(:push) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }

  let(:service) do
    described_class.new(project, user, { ref: 'refs/heads/master' })
  end

  before do
    stub_ci_pipeline_yaml_file(YAML.dump(config))
  end

  shared_examples 'supported cross project artifacts definitions' do
    let(:config) do
      {
        build_job: {
          stage: 'build',
          needs: needs,
          script: ['make']
        }
      }
    end

    let(:needs) do
      [
        { project: 'project-1', job: 'job-1', ref: 'ref-1', artifacts: true },
        { project: 'project-2', job: 'job-2', ref: 'ref-2', artifacts: false },
        { project: 'project-3', job: 'job-3', ref: 'ref-3', artifacts: nil },
        { project: 'project-4', job: 'job-4', ref: 'ref-4' }
      ]
    end

    let(:build_job) { subject.payload.builds.find_by!(name: :build_job) }

    it 'persists pipeline' do
      expect(subject.payload).to be_persisted
    end

    it 'persists job' do
      expect { execute }.to change(Ci::Build, :count).by(1)
    end

    it 'persists cross_dependencies' do
      deps = build_job.options[:cross_dependencies]
      result = [
        { job: "job-1", ref: "ref-1", project: "project-1", artifacts: true },
        { job: "job-2", ref: "ref-2", project: "project-2", artifacts: false },
        { job: "job-3", ref: "ref-3", project: "project-3", artifacts: true },
        { job: "job-4", ref: "ref-4", project: "project-4", artifacts: true }
      ]

      expect(deps).to match(result)
    end

    it 'returns empty dependencies with non existing projects' do
      expect(build_job.all_dependencies).to be_empty
    end
  end

  shared_examples 'mixed artifacts definitions' do
    before do
      other_project.add_developer(user)
    end

    let(:other_project) { create(:project, :repository) }

    let(:other_pipeline) do
      create(:ci_pipeline, project: other_project,
        sha: other_project.commit.id,
        ref: other_project.default_branch,
        status: 'success',
        user: user)
    end

    let!(:dependency) do
      create(:ci_build, :success,
        pipeline: other_pipeline, ref: other_pipeline.ref,
        name: 'dependency', stage_idx: 3, stage: 'deploy', user: user
      )
    end

    let(:config) do
      {
        build_job_1: {
          stage: 'build',
          script: ['make']
        },
        build_job_2: {
          stage: 'build',
          script: ['make']
        },
        test_job: {
          stage: 'test',
          needs: needs,
          script: ['make']
        }
      }
    end

    let(:needs) do
      [
        'build_job_1',
        { job: 'build_job_2', artifacts: false },
        {
          project: other_project.full_path,
          job: dependency.name,
          ref: other_pipeline.ref,
          artifacts: true
        }
      ]
    end

    let(:dependencies_when_license_is_available) do
      %w[dependency] + dependencies_when_license_is_not_available
    end

    let(:dependencies_when_license_is_not_available) do
      %w[build_job_1]
    end

    let(:test_job) { subject.payload.builds.find_by!(name: :test_job) }

    it 'persists pipeline' do
      expect(subject.payload).to be_persisted
    end

    it 'persists jobs' do
      expect { execute }.to change(Ci::Build, :count).by(3)
    end

    it 'persists needs' do
      expect { execute }.to change(Ci::BuildNeed, :count).by(2)

      expect(test_job.needs.map(&:name)).to match(
        a_collection_containing_exactly('build_job_1', 'build_job_2'))
    end

    it 'persists cross_dependencies' do
      deps = test_job.options[:cross_dependencies]
      result = {
        job: 'dependency',
        ref: 'master',
        project: other_project.full_path,
        artifacts: true
      }

      expect(deps).to match(a_collection_containing_exactly(result))
    end

    it 'returns dependencies' do
      names = test_job.all_dependencies.map(&:name)

      expect(names).to match(
        a_collection_containing_exactly(*expected_dependencies))
    end
  end

  shared_examples 'broken artifacts definitions' do
    let(:config) do
      {
        build_job: {
          stage: 'build',
          script: ['make'],
          needs: [
            { project: 'project-2', job: 'job', artifacts: true }
          ]
        }
      }
    end

    it 'persists pipeline' do
      expect(subject.payload).to be_persisted
    end

    it 'has errors' do
      expect(subject.payload.yaml_errors)
        .to include('jobs:build_job:needs:need ref should be a string')
    end
  end

  context 'with license' do
    before do
      stub_licensed_features(cross_project_pipelines: true)
    end

    it_behaves_like 'supported cross project artifacts definitions'
    it_behaves_like 'broken artifacts definitions'
    it_behaves_like 'mixed artifacts definitions' do
      let(:expected_dependencies) { dependencies_when_license_is_available }
    end
  end

  context 'without license' do
    before do
      stub_licensed_features(cross_project_pipelines: false)
    end

    it_behaves_like 'supported cross project artifacts definitions'
    it_behaves_like 'broken artifacts definitions'
    it_behaves_like 'mixed artifacts definitions' do
      let(:expected_dependencies) { dependencies_when_license_is_not_available }
    end
  end
end
