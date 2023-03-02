# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::DestroyBatchService, feature_category: :build_artifacts do
  include EE::GeoHelpers

  describe '.execute' do
    subject { service.execute }

    let(:service) { described_class.new(Ci::JobArtifact.all, pick_up_at: Time.current) }

    let_it_be(:artifact) { create(:ci_job_artifact, :zip) }
    let_it_be(:event_data) { { job_ids: [artifact.job_id] } }

    it 'destroys all expired artifacts', :sidekiq_inline do
      expect { subject }.to change { Ci::JobArtifact.count }.by(-1)
    end

    it 'publishes Ci::JobArtifactsDeletedEvent' do
      expect { subject }.to publish_event(Ci::JobArtifactsDeletedEvent).with(event_data)
    end

    context 'with Geo replication' do
      let_it_be(:primary) { create(:geo_node, :primary) }
      let_it_be(:secondary) { create(:geo_node) }

      before do
        stub_current_geo_node(primary)
        create(:ee_ci_job_artifact, :archive)
      end

      it 'creates an Geo::EventLog', :sidekiq_inline do
        expect { subject }.to change { ::Geo::Event.count }.by(2)
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
        end
      end
    end
  end
end
