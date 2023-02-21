# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::Gitlab::Scim::DeprovisioningService, feature_category: :system_access do
  describe '#execute' do
    let(:identity) { create(:scim_identity, active: true) }
    let(:user) { identity.user }

    let(:service) { described_class.new(identity) }

    context 'when user is successfully removed' do
      it 'deactivates scim identity' do
        expect { service.execute }.to change { identity.active }.from(true).to(false)
      end

      it 'blocks the user' do
        service.execute

        expect(user.ldap_blocked?).to eq(true)
      end

      it 'returns the successful deprovision message' do
        response = service.execute

        expect(response.message).to include("User #{user.name} SCIM identity is deactivated")
      end
    end
  end
end
