# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::Gitlab::Scim::ReprovisioningService, feature_category: :system_access do
  include LoginHelpers

  describe '#execute' do
    let_it_be(:identity) { create(:scim_identity, active: false) }
    let_it_be(:user) { identity.user }
    let!(:saml_provider) do
      stub_basic_saml_config
    end

    let(:service) { described_class.new(identity) }

    it 'activates scim identity' do
      service.execute

      expect(user).to be_active
    end

    it 'activates the user which was in blocked state' do
      user.ldap_block

      service.execute

      expect(user.state).to eq('active')
    end

    it 'returns the successful reprovisiong message' do
      response = service.execute

      expect(response.message).to include("User #{user.name} SCIM identity is reactivated")
    end
  end
end
