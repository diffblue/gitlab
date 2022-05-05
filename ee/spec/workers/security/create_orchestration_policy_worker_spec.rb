# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CreateOrchestrationPolicyWorker do
  describe '#perform' do
    let(:configuration) { create(:security_orchestration_policy_configuration, configured_at: configured_at) }

    subject(:worker) { described_class.new }

    context 'when newly created' do
      let(:configured_at) { nil }

      it 'calls update_policy_configuration' do
        expect(worker).to receive(:update_policy_configuration).with(configuration)

        worker.perform
      end
    end

    context 'when project has been updated earlier than configuration policy', :freeze_time do
      let(:configured_at) { 10.minutes.from_now }

      before do
        allow(configuration.security_policy_management_project).to receive(:last_repository_updated_at) { Time.current }
      end

      it 'does not call update_policy_configuration' do
        expect(worker).not_to receive(:update_policy_configuration)

        worker.perform
      end
    end
  end
end
