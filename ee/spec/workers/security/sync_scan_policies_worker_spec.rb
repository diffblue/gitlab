# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SyncScanPoliciesWorker, feature_category: :security_policy_management do
  describe '#perform' do
    let_it_be(:configuration) { create(:security_orchestration_policy_configuration, configured_at: nil) }

    subject(:worker) { described_class.new }

    it 'calls update_policy_configuration' do
      expect(worker).to receive(:update_policy_configuration).with(configuration)

      worker.perform(configuration.id)
    end

    it 'does not call update_policy_configuration when configuration is not present' do
      expect(worker).not_to receive(:update_policy_configuration)

      worker.perform(non_existing_record_id)
    end
  end
end
