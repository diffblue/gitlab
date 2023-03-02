# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TriggerDownstreamSubscriptionService, feature_category: :continuous_integration do
  describe '#execute' do
    subject(:execute) { described_class.new(pipeline.project, pipeline.user).execute(pipeline) }

    let!(:pipeline) { create(:ci_pipeline, project: upstream_project) }
    let(:upstream_project) { create(:project, :public) }

    before do
      stub_ci_pipeline_yaml_file(YAML.dump(job_name: { script: 'echo 1' }))
    end

    context 'when pipeline project has downstream projects' do
      let(:downstream_project) { create(:project, :repository) }

      let!(:subscription) do
        create(
          :ci_subscriptions_project,
          upstream_project: upstream_project,
          downstream_project: downstream_project,
          author: author
        )
      end

      shared_examples 'creates a downstream pipeline' do
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

      context 'when subscription has an author' do
        let(:author) { create(:user) }

        before do
          downstream_project.add_developer(author)
        end

        it_behaves_like 'creates a downstream pipeline'

        it 'uses the subscription author as pipeline user' do
          execute

          expect(Ci::Pipeline.last.user).to eq(author)
        end
      end

      context 'when the legacy subscription does not have an author' do
        let(:author) { nil }

        it_behaves_like 'creates a downstream pipeline'

        it 'uses the downstream project creator as pipeline user' do
          execute

          expect(Ci::Pipeline.last.user).to eq(downstream_project.creator)
        end

        context 'when project creator no longer exists' do
          before do
            downstream_project.update!(creator: nil)
          end

          it 'does not create a downstream pipeline' do
            expect { execute }
              .not_to change { Ci::Pipeline.count }.from(1)
          end
        end
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
