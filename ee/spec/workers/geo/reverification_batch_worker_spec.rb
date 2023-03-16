# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ReverificationBatchWorker, :geo, feature_category: :geo_replication do
  include EE::GeoHelpers

  let(:node) { create(:geo_node, :primary) }

  subject(:job) { described_class.new }

  before do
    stub_current_geo_node(node)
  end

  it 'uses a Geo queue' do
    expect(job.sidekiq_options_hash).to include(
      'queue_namespace' => :geo
    )
  end

  describe '#perform' do
    let(:replicable_name) { 'widget' }
    let(:replicator_class) { double('widget_replicator_class') }

    before do
      allow(::Gitlab::Geo::Replicator)
        .to receive(:for_replicable_name).with(replicable_name).and_return(replicator_class)
    end

    it 'calls reverify_batch!' do
      allow(replicator_class).to receive(:remaining_reverification_batch_count).and_return(1)

      expect(replicator_class).to receive(:reverify_batch!)

      job.perform(replicable_name)
    end
  end

  include_examples 'an idempotent worker' do
    let(:job_args) { ['package_file'] }
  end
end
