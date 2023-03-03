# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupSaml::SignUpService, feature_category: :system_access do
  subject(:service) { described_class.new(new_user, group, session) }

  let(:new_user) { build(:user) }
  let!(:group) { create(:saml_provider).group }
  let(:session) { { 'oauth_data' => {} } }

  describe '#execute' do
    let(:linker_spy) { spy('Gitlab::Auth::GroupSaml::IdentityLinker') }

    before do
      allow(Gitlab::Auth::GroupSaml::IdentityLinker)
        .to receive(:new).with(new_user, session['oauth_data'], session, group.saml_provider)
              .and_return(linker_spy)
    end

    it 'creates new user' do
      expect { service.execute }.to change { User.count }.by(1)
    end

    it 'links new user to oauth identity' do
      service.execute

      expect(linker_spy).to have_received(:link)
    end

    context 'when group has enforced_group_managed_accounts enabled' do
      before do
        allow(group.saml_provider).to receive(:enforced_group_managed_accounts?).and_return(true)
      end

      it 'creates new user managed by given group' do
        expect { service.execute }.to change { group.managed_users.count }.by(1)
      end
    end
  end
end
