# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::VerificationCronWorker, :geo do
  describe '#perform' do
    it 'calls trigger_background_verification on enabled Replicators' do
      replicator = double('replicator')

      expect(replicator).to receive(:trigger_background_verification)
      expect(Gitlab::Geo).to receive(:verification_enabled_replicator_classes).and_return([replicator])

      described_class.new.perform
    end
  end

  it 'uses a cronjob queue' do
    expect(subject.sidekiq_options_hash).to include(
      'queue' => 'cronjob:geo_verification_cron',
      'queue_namespace' => :cronjob
    )
  end
end
