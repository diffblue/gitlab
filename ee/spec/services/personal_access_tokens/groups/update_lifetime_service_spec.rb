# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::Groups::UpdateLifetimeService, feature_category: :system_access do
  include ExclusiveLeaseHelpers

  describe '#execute', :clean_gitlab_redis_shared_state do
    let_it_be(:group) { create(:group_with_managed_accounts) }

    subject { described_class.new(group) }

    let(:lease_key) { "personal_access_tokens/groups/update_lifetime_service:group_id:#{group.id}" }

    context 'when we can obtain the lease' do
      it 'schedules the worker' do
        stub_exclusive_lease(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)

        expect(::PersonalAccessTokens::Groups::PolicyWorker).to receive(:perform_in).once

        subject.execute
      end
    end

    context "when we can't obtain the lease" do
      it 'does not schedule the worker' do
        stub_exclusive_lease_taken(lease_key, timeout: described_class::DEFAULT_LEASE_TIMEOUT)

        expect(::PersonalAccessTokens::Groups::PolicyWorker).not_to receive(:perform_in)

        subject.execute
      end
    end
  end
end
