# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::Instance::UpdateLifetimeService, feature_category: :system_access do
  describe '#execute', :clean_gitlab_redis_shared_state do
    include ExclusiveLeaseHelpers

    let(:lease_key) { 'personal_access_tokens/instance/update_lifetime_service' }

    context 'when we can obtain the lease' do
      it 'schedules the worker' do
        stub_exclusive_lease(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)

        expect(::PersonalAccessTokens::Instance::PolicyWorker).to receive(:perform_in).once

        subject.execute
      end
    end

    context "when we can't obtain the lease" do
      it 'does not schedule the worker' do
        stub_exclusive_lease_taken(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)

        expect(::PersonalAccessTokens::Instance::PolicyWorker).not_to receive(:perform_in)

        subject.execute
      end
    end
  end
end
