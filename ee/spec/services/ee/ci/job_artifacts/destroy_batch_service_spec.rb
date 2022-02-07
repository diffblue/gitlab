# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::DestroyBatchService do
  include EE::GeoHelpers

  describe '.execute' do
    subject { service.execute }

    let(:service) { described_class.new(Ci::JobArtifact.all, pick_up_at: Time.current) }

    let_it_be(:artifact) { create(:ci_job_artifact) }
    let_it_be(:security_scan) { create(:security_scan, build: artifact.job) }
    let_it_be(:security_finding) { create(:security_finding, scan: security_scan) }
    let_it_be(:event_data) { { job_ids: [artifact.job_id] } }

    it 'destroys all expired artifacts', :sidekiq_inline do
      expect { subject }.to change { Ci::JobArtifact.count }.by(-1)
                        .and change { Security::Finding.count }.from(1).to(0)
    end

    it 'publishes Ci::JobArtifactsDeletedEvent' do
      event = double(:event)

      expect(Ci::JobArtifactsDeletedEvent)
        .to receive(:new)
        .with(data: event_data)
        .and_return(event)

      expect(Gitlab::EventStore).to receive(:publish).with(event)

      subject
    end

    context 'with Geo replication' do
      let_it_be(:primary) { create(:geo_node, :primary) }
      let_it_be(:secondary) { create(:geo_node) }

      before do
        stub_current_geo_node(primary)
        create(:ee_ci_job_artifact, :archive)
      end

      it 'creates a JobArtifactDeletedEvent' do
        expect { subject }.to change { Geo::JobArtifactDeletedEvent.count }.by(1)
      end

      context 'JobArtifact batch destroy fails' do
        before do
          expect(Ci::DeletedObject)
            .to receive(:bulk_import)
            .once
            .and_raise(ActiveRecord::RecordInvalid)
        end

        it 'does not create a JobArtifactDeletedEvent' do
          expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
                            .and not_change { Ci::JobArtifact.count }
                            .and not_change { Geo::JobArtifactDeletedEvent.count }
        end
      end
    end
  end
end
