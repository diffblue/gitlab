# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Saml::MembershipUpdater do
  let_it_be(:user) { create(:user) }
  let_it_be(:group1) { create(:group) }
  let_it_be(:group2) { create(:group) }

  let(:auth_hash) do
    Gitlab::Auth::GroupSaml::AuthHash.new(
      OmniAuth::AuthHash.new(extra: {
        raw_info: OneLogin::RubySaml::Attributes.new('groups' => %w(Developers Owners))
      })
    )
  end

  subject(:update_membership) { described_class.new(user, auth_hash).execute }

  context 'when SAML group links exist' do
    def stub_saml_group_sync_enabled(enabled)
      allow(::Gitlab::Auth::Saml::Config).to receive(:group_sync_enabled?).and_return(enabled)
    end

    let!(:group_link) { create(:saml_group_link, saml_group_name: 'Owners', group: group1) }

    context 'when group sync is not available' do
      before do
        stub_saml_group_sync_enabled(false)
      end

      it 'does not enqueue group sync' do
        expect(::Auth::SamlGroupSyncWorker).not_to receive(:perform_async)

        update_membership
      end
    end

    context 'when group sync is available' do
      before do
        stub_saml_group_sync_enabled(true)
      end

      it 'enqueues group sync' do
        expect(::Auth::SamlGroupSyncWorker).to receive(:perform_async).with(user.id, match_array(group_link.id))

        update_membership
      end

      context 'when auth hash contains no groups' do
        let(:auth_hash) do
          Gitlab::Auth::GroupSaml::AuthHash.new(
            OmniAuth::AuthHash.new(extra: { raw_info: OneLogin::RubySaml::Attributes.new })
          )
        end

        it 'enqueues group sync' do
          expect(::Auth::SamlGroupSyncWorker).to receive(:perform_async).with(user.id, [])

          update_membership
        end
      end

      context 'when auth hash groups do not match group links' do
        before do
          group_link.update!(saml_group_name: 'Web Developers')
        end

        it 'enqueues group sync' do
          expect(::Auth::SamlGroupSyncWorker).to receive(:perform_async).with(user.id, [])

          update_membership
        end
      end
    end
  end
end
