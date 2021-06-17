# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, :sidekiq_inline do
  let_it_be(:namespace) { create(:namespace, :with_used_build_minutes_limit) }
  let_it_be(:project) { create(:project, :repository, namespace: namespace) }
  let_it_be(:user) { project.owner }
  let_it_be(:instance_runner) { create(:ci_runner, :instance, :online) }

  let(:service) do
    described_class.new(project, user, { ref: 'refs/heads/master' })
  end

  let(:config) do
    <<~EOY
    job1:
     stage: build
     script:
       - echo "deploy runner 123"

    job2:
      stage: test
      script:
        - echo "run on runner 123"
      tags:
        - "123"
    EOY
  end

  before do
    project.add_developer(user)
    stub_ci_pipeline_yaml_file(config)
  end

  it 'drops builds that match shared runners', :aggregate_failures do
    pipeline = create_pipeline

    job1 = pipeline.builds.find_by_name('job1')
    job2 = pipeline.builds.find_by_name('job2')

    expect(job1).to be_failed
    expect(job1.failure_reason).to eq('ci_quota_exceeded')
    expect(job2).not_to be_failed
  end

  context 'with private runners' do
    let_it_be(:private_runner) do
      create(:ci_runner, :project, :online, projects: [project])
    end

    it 'does not drop the builds', :aggregate_failures do
      pipeline = create_pipeline

      job1 = pipeline.builds.find_by_name('job1')
      job2 = pipeline.builds.find_by_name('job2')

      expect(job1).not_to be_failed
      expect(job2).not_to be_failed
    end
  end

  def create_pipeline
    service.execute(:push).payload
  end
end
