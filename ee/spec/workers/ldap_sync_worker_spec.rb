# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LdapSyncWorker, feature_category: :system_access do
  let(:subject) { described_class.new }

  before do
    allow(Sidekiq.logger).to receive(:info)
    allow(Gitlab::Auth::Ldap::Config).to receive(:enabled?).and_return(true)

    create(:omniauth_user, provider: 'ldapmain')
  end

  describe '#perform' do
    context 'with the default license key' do
      it 'syncs all LDAP users' do
        expect(Gitlab::Auth::Ldap::Access).to receive(:allowed?)

        subject.perform
      end
    end

    context 'without a license key' do
      before do
        License.destroy_all # rubocop: disable Cop/DestroyAll
      end

      it 'does not sync LDAP users' do
        expect(Gitlab::Auth::Ldap::Access).not_to receive(:allowed?)

        subject.perform
      end
    end
  end
end
