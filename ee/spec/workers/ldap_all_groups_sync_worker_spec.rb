# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LdapAllGroupsSyncWorker, feature_category: :system_access do
  let(:subject) { described_class.new }

  before do
    allow(Sidekiq.logger).to receive(:info)
    allow(Gitlab::Auth::Ldap::Config).to receive(:enabled?).and_return(true)
  end

  describe '#perform' do
    context 'with the default license key' do
      it 'syncs all groups when group_id is nil' do
        expect(EE::Gitlab::Auth::Ldap::Sync::Groups).to receive(:execute)

        subject.perform
      end
    end

    context 'without a license key' do
      before do
        License.destroy_all # rubocop: disable Cop/DestroyAll
      end

      it 'does not sync all groups' do
        expect(EE::Gitlab::Auth::Ldap::Sync::Groups).not_to receive(:execute)

        subject.perform
      end
    end
  end
end
