# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::OrphanJobArtifactFiles do
  include ::EE::GeoHelpers

  let(:null_logger) { Logger.new('/dev/null') }

  subject(:cleanup) { described_class.new(logger: null_logger) }

  before do
    allow(null_logger).to receive(:info)
  end

  context 'not a Geo secondary' do
    it 'does not print cleaning Geo registries message' do
      expect(null_logger).not_to receive(:info).with(/Geo/)

      cleanup.run!
    end
  end

  context 'Geo secondary', :geo do
    before do
      stub_secondary_node
    end

    it 'prints cleaning Geo registries message' do
      expect(null_logger).to receive(:info).with(/delete \d+ Geo registry records/)

      cleanup.run!
    end

    it 'accumulates the number of cleaned Geo registries' do
      stub_const("#{described_class.name}::BATCH_SIZE", 2)
      create_list(:geo_job_artifact_registry, 3, :orphan)
      create(:ci_job_artifact, :archive).delete

      cleanup.run!

      expect(cleanup.total_geo_registries).to eq(3)
    end
  end
end
