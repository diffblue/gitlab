# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::SyncReportsToReportApprovalRulesWorker, feature_category: :source_code_management do
  describe '#perform' do
    let(:pipeline) { double(:pipeline, id: 42) }
    let(:sync_service) { double(:service, execute: true) }

    context 'when pipeline exists' do
      before do
        allow(Ci::Pipeline).to receive(:find_by_id).with(pipeline.id) { pipeline }
      end

      it "executes SyncReportsToApprovalRulesService for given pipeline" do
        expect(Ci::SyncReportsToApprovalRulesService).to receive(:new)
          .with(pipeline).once.and_return(sync_service)

        described_class.new.perform(pipeline.id)
      end
    end

    context 'when pipeline is missing' do
      it 'does not execute SyncReportsToApprovalRulesService' do
        expect(Ci::SyncReportsToApprovalRulesService).not_to receive(:new)

        described_class.new.perform(pipeline.id)
      end
    end
  end
end
