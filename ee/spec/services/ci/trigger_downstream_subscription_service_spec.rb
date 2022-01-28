# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TriggerDownstreamSubscriptionService do
  describe '#execute' do
    subject(:execute) { described_class.new(pipeline.project, pipeline.user).execute(pipeline) }

    let(:upstream_project) { create(:project, :public) }
    let(:pipeline) { create(:ci_pipeline, project: upstream_project, user: create(:user)) }

    before do
      stub_ci_pipeline_yaml_file(YAML.dump(job_name: { script: 'echo 1' }))
    end

    context 'when pipeline project has downstream projects' do
      let(:downstream_project) { create(:project, :repository, upstream_projects: [upstream_project]) }

      before do
        downstream_project.add_developer(pipeline.user)
      end

      it 'associates the downstream pipeline with the upstream project' do
        expect { execute }
          .to change { Ci::Sources::Project.count }.from(0).to(1)
          .and change { Ci::Pipeline.count }.from(1).to(2)

        project_source = Ci::Sources::Project.last
        new_pipeline = Ci::Pipeline.last
        expect(project_source.pipeline).to eq(new_pipeline)
        expect(project_source.source_project_id).to eq(pipeline.project_id)
      end
    end

    context 'when pipeline project does not have downstream projects' do
      it 'does not call the create pipeline service' do
        expect(::Ci::CreatePipelineService).not_to receive(:new)

        execute
      end
    end
  end
end
