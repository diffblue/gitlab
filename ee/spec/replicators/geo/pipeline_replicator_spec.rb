# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::PipelineReplicator, feature_category: :geo_replication do
  include EE::GeoHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:model_record) { build(:ci_pipeline, project: project) }

  let(:replicator) { model_record.replicator }

  describe '.model' do
    it 'is a pipeline' do
      expect(described_class.model).to be(Ci::Pipeline)
    end
  end

  describe '#log_geo_pipeline_ref_created_event' do
    subject { replicator.log_geo_pipeline_ref_created_event }

    context 'without Geo enabled' do
      it 'does not publish an event' do
        expect(replicator).not_to receive(:publish)

        expect { subject }.not_to change { ::Geo::Event.count }
      end
    end

    context 'on a Geo primary' do
      before do
        stub_primary_node
      end

      it 'creates a Geo event' do
        expect { subject }.to change { ::Geo::Event.count }.by(1)

        expect(::Geo::Event.last.attributes).to include(
          "replicable_name" => replicator.replicable_name,
          "event_name" => "pipeline_ref_created",
          "payload" => {
            "model_record_id" => replicator.model_record.id
          }
        )
      end
    end

    context 'on a Geo secondary' do
      before do
        stub_secondary_node
      end

      it 'does not publish an event' do
        expect(replicator).not_to receive(:publish)

        expect { subject }.not_to change { ::Geo::Event.count }
      end
    end
  end

  describe '#consume_event_pipeline_ref_created' do
    subject(:consume_event) { replicator.consume_event_pipeline_ref_created }

    it 'ensures a pipeline ref exists' do
      expect(model_record).to receive(:ensure_persistent_ref)

      consume_event
    end
  end
end
