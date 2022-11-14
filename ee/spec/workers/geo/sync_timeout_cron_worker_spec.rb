# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::SyncTimeoutCronWorker, :geo do
  describe '#perform' do
    it 'calls fail_sync_timeouts' do
      replicator = double('replicator')

      expect(replicator).to receive(:fail_sync_timeouts)
      expect(Gitlab::Geo).to receive(:enabled_replicator_classes).and_return([replicator])
      expect(Geo::ContainerRepositoryRegistry).to receive(:fail_sync_timeouts)

      described_class.new.perform
    end
  end

  it 'uses a cronjob queue' do
    expect(subject.sidekiq_options_hash).to include(
      'queue' => 'cronjob:geo_sync_timeout_cron',
      'queue_namespace' => :cronjob
    )
  end
end
