# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Scans::PurgeWorker do
  describe '#perform' do
    subject(:perform) { described_class.new.perform }

    before do
      allow(::Security::PurgeScansService).to receive(:purge_stale_records)

      stub_feature_flags(purge_stale_security_findings: feature_enabled?)
    end

    context 'when the `purge_stale_security_findings` feature is disabled' do
      let(:feature_enabled?) { false }

      it 'does not initiate the mark as purged job' do
        perform

        expect(::Security::PurgeScansService).not_to have_received(:purge_stale_records)
      end
    end

    context 'when the `purge_stale_security_findings` feature is enabled' do
      let(:feature_enabled?) { true }

      it 'initiates the mark as purged job' do
        perform

        expect(::Security::PurgeScansService).to have_received(:purge_stale_records)
      end
    end
  end
end
