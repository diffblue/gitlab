# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SyncScanPoliciesWorker do
  describe '#perform' do
    let_it_be(:configuration) { create(:security_orchestration_policy_configuration, configured_at: nil) }

    subject(:worker) { described_class.new }

    it 'calls update_policy_configuration' do
      expect(worker).to receive(:update_policy_configuration).with(configuration)

      worker.perform(configuration.id)
    end
  end
end
