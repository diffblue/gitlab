# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Scans::PurgeWorker, feature_category: :vulnerability_management do
  describe '#perform' do
    subject(:perform) { described_class.new.perform }

    before do
      allow(::Security::PurgeScansService).to receive(:purge_stale_records)
    end

    it 'delegates the call to PurgeScansService' do
      perform

      expect(::Security::PurgeScansService).to have_received(:purge_stale_records)
    end
  end
end
