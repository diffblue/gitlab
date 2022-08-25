# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Ldap::Config do
  include LdapHelpers

  describe '.available_providers' do
    before do
      stub_ldap_setting(
        'enabled' => true,
        'servers' => {
          'main' => { 'provider_name' => 'ldapmain' },
          'secondary' => { 'provider_name' => 'ldapsecondary' }
        }
      )
    end

    context 'when multiple LDAP servers are licensed' do
      before do
        stub_licensed_features(multiple_ldap_servers: true)
      end

      it 'returns multiple configured providers' do
        expect(described_class.available_providers).to match_array(%w(ldapmain ldapsecondary))
      end
    end
  end

  describe '._available_servers' do
    context 'when no database connection occurs' do
      before do
        allow(::License).to receive(:feature_available?).and_raise(ActiveRecord::NoDatabaseError)
      end

      it 'returns an empty array' do
        expect(described_class._available_servers).to eq([])
      end
    end
  end
end
