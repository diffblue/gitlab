# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::SubscribeBridgeService, feature_category: :continuous_integration do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:bridge) { build(:ci_bridge, upstream: upstream_project) }

  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    subject { service.execute(bridge) }

    context 'when the upstream project exists' do
      let(:upstream_project) { create(:project, :repository) }

      context 'when the upstream project has a pipeline' do
        let!(:upstream_pipeline) do
          create(:ci_pipeline,
            project: upstream_project,
            ref: upstream_project.default_branch,
            sha: upstream_project.commit.sha)
        end

        context 'when the user has permissions' do
          before do
            upstream_project.add_developer(user)
          end

          it 'populates the pipeline project source' do
            subject

            expect(bridge.upstream_pipeline).to eq(upstream_pipeline)
          end

          context 'when the pipeline already finished' do
            before do
              upstream_pipeline.succeed!
            end

            it 'mirrors the pipeline status to the bridge job instantly' do
              expect { subject }.to change { bridge.status }.from('created').to(upstream_pipeline.status)
            end
          end

          it 'persists the bridge' do
            subject

            expect(bridge).to be_persisted
          end
        end

        context 'when the user does not have permissions' do
          it 'drops the bridge' do
            subject

            expect(bridge.upstream_pipeline).to eq(nil)
            expect(bridge.status).to eq('failed')
            expect(bridge.failure_reason).to eq('insufficient_upstream_permissions')
          end
        end
      end

      context 'when the upstream project does not have a pipeline' do
        it 'skips the bridge' do
          subject

          expect(bridge.upstream_pipeline).to eq(nil)
          expect(bridge.status).to eq('skipped')
        end
      end
    end

    context 'when the upstream project does not exist' do
      let(:upstream_project) { nil }

      before do
        bridge.options = { bridge_needs: { pipeline: 'some/project' } }
      end

      it 'drops the bridge' do
        subject

        expect(bridge.upstream_pipeline).to eq(nil)
        expect(bridge.status).to eq('failed')
        expect(bridge.failure_reason).to eq('upstream_bridge_project_not_found')
      end
    end
  end
end
