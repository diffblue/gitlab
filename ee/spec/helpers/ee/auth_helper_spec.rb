# frozen_string_literal: true
#
require 'spec_helper'

RSpec.describe EE::AuthHelper do
  describe "button_based_providers" do
    it 'excludes group_saml' do
      allow(helper).to receive(:auth_providers) { [:group_saml] }
      expect(helper.button_based_providers).to eq([])
    end
  end

  describe "providers_for_base_controller" do
    it 'excludes group_saml' do
      allow(helper).to receive(:auth_providers) { [:group_saml] }
      expect(helper.providers_for_base_controller).to eq([])
    end
  end

  describe 'form_based_auth_provider_has_active_class?' do
    it 'selects main LDAP server' do
      allow(helper).to receive(:auth_providers) { [:twitter, :ldapprimary, :ldapsecondary] }
      expect(helper.form_based_auth_provider_has_active_class?(:twitter)).to be(false)
      expect(helper.form_based_auth_provider_has_active_class?(:ldapprimary)).to be(true)
      expect(helper.form_based_auth_provider_has_active_class?(:ldapsecondary)).to be(false)
    end
  end

  describe "form_based_providers" do
    context 'with smartcard_auth feature flag off' do
      before do
        stub_licensed_features(smartcard_auth: false)
        allow(helper).to receive(:smartcard_enabled?).and_call_original
      end

      it 'does not include smartcard provider' do
        allow(helper).to receive(:auth_providers) { [:twitter, :smartcard] }
        expect(helper.form_based_providers).to be_empty
      end
    end

    context 'with smartcard_auth feature flag on' do
      before do
        stub_licensed_features(smartcard_auth: true)
        allow(helper).to receive(:smartcard_enabled?).and_return(true)
      end

      it 'includes smartcard provider' do
        allow(helper).to receive(:auth_providers) { [:twitter, :smartcard] }
        expect(helper.form_based_providers).to eq %i(smartcard)
      end
    end
  end

  describe 'smartcard_enabled_for_ldap?' do
    let(:provider_name) { 'ldapmain' }
    let(:ldap_server_config) do
      {
        'provider_name' => provider_name,
        'attributes' => {},
        'encryption' => 'plain',
        'smartcard_auth' => smartcard_auth_status,
        'uid' => 'uid',
        'base' => 'dc=example,dc=com'
      }
    end

    before do
      allow(::Gitlab::Auth::Smartcard).to receive(:enabled?).and_return(true)
      allow(::Gitlab::Auth::Ldap::Config).to receive(:servers).and_return([ldap_server_config])
    end

    context 'LDAP server with optional smartcard auth' do
      let(:smartcard_auth_status) { 'optional' }

      it 'returns true' do
        expect(smartcard_enabled_for_ldap?(provider_name, required: false)).to be(true)
      end

      it 'returns false with required flag' do
        expect(smartcard_enabled_for_ldap?(provider_name, required: true)).to be(false)
      end
    end

    context 'LDAP server with required smartcard auth' do
      let(:smartcard_auth_status) { 'required' }

      it 'returns true' do
        expect(smartcard_enabled_for_ldap?(provider_name, required: false)).to be(true)
      end

      it 'returns true with required flag' do
        expect(smartcard_enabled_for_ldap?(provider_name, required: true)).to be(true)
      end
    end

    context 'LDAP server with disabled smartcard auth' do
      let(:smartcard_auth_status) { false }

      it 'returns false' do
        expect(smartcard_enabled_for_ldap?(provider_name, required: false)).to be(false)
      end

      it 'returns false with required flag' do
        expect(smartcard_enabled_for_ldap?(provider_name, required: true)).to be(false)
      end
    end

    context 'no matching LDAP server' do
      let(:smartcard_auth_status) { 'optional' }

      it 'returns false' do
        expect(smartcard_enabled_for_ldap?('nonexistent')).to be(false)
      end
    end
  end

  describe 'smartcard_login_button_classes' do
    let(:provider_name) { 'ldapmain' }
    let(:ldap_server_config) do
      {
        'provider_name' => provider_name,
        'attributes' => {},
        'encryption' => 'plain',
        'smartcard_auth' => smartcard_auth_status,
        'uid' => 'uid',
        'base' => 'dc=example,dc=com'
      }
    end

    subject { smartcard_login_button_classes(provider_name) }

    before do
      allow(::Gitlab::Auth::Smartcard).to receive(:enabled?).and_return(true)
      allow(::Gitlab::Auth::Ldap::Config).to receive(:servers).and_return([ldap_server_config])
    end

    context 'when smartcard auth is optional' do
      let(:smartcard_auth_status) { 'optional' }

      it 'returns the correct CSS classes' do
        expect(subject).to eql('btn btn-success btn-inverted')
      end
    end

    context 'when smartcard auth is required' do
      let(:smartcard_auth_status) { 'required' }

      it 'returns the correct CSS classes' do
        expect(subject).to eql('btn btn-success')
      end
    end
  end

  describe '#password_rule_list' do
    context 'when password complexity feature is not available' do
      it 'returns nil' do
        expect(password_rule_list).to be_nil
      end
    end

    context 'when password complexity feature is available' do
      before do
        stub_licensed_features(password_complexity: true)
      end

      context 'without any rules' do
        it 'returns an empty array' do
          expect(password_rule_list).to match_array([])
        end
      end

      context 'with one rule' do
        before do
          stub_application_setting(password_number_required: true)
        end

        it 'returns only one rule' do
          expect(password_rule_list).to match_array([:number])
        end
      end

      context 'with all rules' do
        before do
          stub_application_setting(password_number_required: true)
          stub_application_setting(password_symbol_required: true)
          stub_application_setting(password_lowercase_required: true)
          stub_application_setting(password_uppercase_required: true)
        end

        it 'returns all rules' do
          expect(password_rule_list).to match_array([:number, :symbol, :lowercase, :uppercase])
        end
      end
    end
  end
end
