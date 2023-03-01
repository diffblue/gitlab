# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineBridgeStatusService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }

  let(:user) { build(:user) }
  let(:pipeline) { build(:ci_pipeline, project: project) }

  describe '#execute' do
    subject { described_class.new(project, user).execute(pipeline) }

    context 'when pipeline has downstream bridges' do
      let(:bridge) { build(:ci_bridge) }

      before do
        pipeline.downstream_bridges << bridge
      end

      it 'calls inherit_status_from_upstream on downstream bridges' do
        expect(bridge).to receive(:inherit_status_from_upstream!)

        subject
      end
    end

    context 'when pipeline has both downstream and upstream bridge' do
      let(:downstream_bridge) { build(:ci_bridge) }
      let(:upstream_bridge) { build(:ci_bridge) }

      before do
        pipeline.downstream_bridges << downstream_bridge
        pipeline.source_bridge = upstream_bridge
      end

      it 'only calls inherit_status_from_downstream on upstream bridge' do
        allow(downstream_bridge).to receive(:inherit_status_from_upstream!)

        expect(upstream_bridge).to receive(:inherit_status_from_downstream!).with(pipeline)
        expect(downstream_bridge).not_to receive(:inherit_status_from_downstream!)

        subject
      end

      it 'only calls inherit_status_from_upstream on downstream bridge' do
        allow(upstream_bridge).to receive(:inherit_status_from_downstream!)

        expect(upstream_bridge).not_to receive(:inherit_status_from_upstream!)
        expect(downstream_bridge).to receive(:inherit_status_from_upstream!)

        subject
      end
    end
  end
end
