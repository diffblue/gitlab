# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Findings::CleanupWorker do
  describe '#perform' do
    subject(:perform) { described_class.new.perform }

    before do
      allow(::Security::Findings::CleanupService).to receive(:delete_stale_records)

      stub_feature_flags(purge_stale_security_findings: feature_enabled?)
    end

    context 'when the `purge_stale_security_findings` feature is disabled' do
      let(:feature_enabled?) { false }

      it 'does not initiate the cleanup job' do
        perform

        expect(::Security::Findings::CleanupService).not_to have_received(:delete_stale_records)
      end
    end

    context 'when the `purge_stale_security_findings` feature is enabled' do
      let(:feature_enabled?) { true }

      it 'initiates the cleanup job' do
        perform

        expect(::Security::Findings::CleanupService).to have_received(:delete_stale_records)
      end
    end
  end
end
