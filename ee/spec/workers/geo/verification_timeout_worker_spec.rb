# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::VerificationTimeoutWorker, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let(:replicable_name) { 'snippet_repository' }

  it 'uses a Geo queue' do
    expect(described_class.new.sidekiq_options_hash).to include(
      'queue_namespace' => :geo
    )
  end

  describe 'perform' do
    context 'secondary node' do
      before do
        stub_secondary_node
      end

      it 'fails timed out records on secondary' do
        registry = create(:geo_snippet_repository_registry, :synced, verification_state: Geo::VerificationState::VERIFICATION_STATE_VALUES[:verification_started], verification_started_at: 3.days.ago)

        described_class.new.perform(replicable_name)

        expect(registry.reload.verification_state).to eq Geo::VerificationState::VERIFICATION_STATE_VALUES[:verification_failed]
      end
    end
  end

  describe 'idempotent behaviour' do
    let(:replicator_class) { double('snippet_repository_replicator_class') }

    before do
      allow(::Gitlab::Geo::Replicator).to receive(:for_replicable_name).with(replicable_name).and_return(replicator_class)

      # This stub is not relevant to the test defined below. This stub is needed
      # for another example defined in `include_examples 'an idempotent
      # worker'`.
      allow(replicator_class).to receive(:fail_verification_timeouts)
    end

    include_examples 'an idempotent worker' do
      let(:job_args) { replicable_name }

      it 'calls fail_verification_timeouts' do
        expect(replicator_class).to receive(:fail_verification_timeouts).exactly(IdempotentWorkerHelper::WORKER_EXEC_TIMES).times

        subject
      end
    end
  end
end
