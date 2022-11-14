# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::VerificationBatchWorker, :geo do
  include EE::GeoHelpers

  let(:replicable_name) { 'widget' }
  let(:replicator_class) { double('widget_replicator_class') }
  let(:node) { double('node') }

  before do
    stub_current_geo_node(node)
  end

  subject(:job) { described_class.new }

  it 'uses a Geo queue' do
    expect(job.sidekiq_options_hash).to include(
      'queue' => 'geo:geo_verification_batch',
      'queue_namespace' => :geo
    )
  end

  describe '#perform' do
    it 'calls verify_batch' do
      allow(::Gitlab::Geo::Replicator).to receive(:for_replicable_name).with(replicable_name).and_return(replicator_class)
      allow(::Gitlab::Geo).to receive(:verification_max_capacity_per_replicator_class).and_return(1)
      allow(replicator_class).to receive(:remaining_verification_batch_count).and_return(1)

      expect(replicator_class).to receive(:verify_batch)

      job.perform(replicable_name)
    end
  end

  describe '#remaining_work_count' do
    it 'returns remaining_verification_batch_count' do
      expected = 7
      args = { max_batch_count: 95 }
      allow(job).to receive(:max_running_jobs).and_return(args[:max_batch_count])
      allow(::Gitlab::Geo::Replicator).to receive(:for_replicable_name).with(replicable_name).and_return(replicator_class)

      expect(replicator_class).to receive(:remaining_verification_batch_count).with(args).and_return(expected)

      expect(job.remaining_work_count(replicable_name)).to eq(expected)
    end
  end

  describe '#max_running_jobs' do
    it 'returns verification_max_capacity_per_replicator_class' do
      allow(::Gitlab::Geo).to receive(:verification_max_capacity_per_replicator_class).and_return(123)

      expect(job.max_running_jobs).to eq(123)
    end
  end
end
