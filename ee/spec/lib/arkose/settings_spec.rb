# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arkose::Settings, feature_category: :instance_resiliency do
  using RSpec::Parameterized::TableSyntax

  describe '.arkose_public_api_key' do
    subject { described_class.arkose_public_api_key }

    context 'when set in application settings' do
      let(:setting_value) { 'setting_public_key' }

      before do
        stub_application_setting(arkose_labs_public_api_key: setting_value)
      end

      it { is_expected.to eq setting_value }
    end

    context 'when NOT set in application settings' do
      let(:env_var_value) { 'env_var_public_key' }

      before do
        stub_env('ARKOSE_LABS_PUBLIC_KEY', env_var_value)
      end

      it { is_expected.to eq env_var_value }
    end
  end

  describe '.arkose_private_api_key' do
    subject { described_class.arkose_private_api_key }

    context 'when set in application settings' do
      let(:setting_value) { 'setting_value' }

      before do
        stub_application_setting(arkose_labs_private_api_key: setting_value)
      end

      it { is_expected.to eq setting_value }
    end

    context 'when NOT set in application settings' do
      let(:env_var_value) { 'env_var_value' }

      before do
        stub_env('ARKOSE_LABS_PRIVATE_KEY', env_var_value)
      end

      it { is_expected.to eq env_var_value }
    end
  end

  describe '.arkose_labs_domain' do
    subject { described_class.arkose_labs_domain }

    let(:setting_value) { 'setting_value' }

    before do
      stub_application_setting(arkose_labs_namespace: setting_value)
    end

    it { is_expected.to eq "#{setting_value}-api.arkoselabs.com" }
  end

  describe '.enabled?' do
    let_it_be(:user) { create(:user) }

    subject { described_class.enabled?(user: user, user_agent: 'user_agent') }

    where(:private_key, :public_key, :namespace, :qa_request, :group_saml_user, :result) do
      nil       | 'public' | 'namespace' | false | false | false
      'private' | nil      | 'namespace' | false | false | false
      'private' | 'public' | nil         | false | false | false
      'private' | 'public' | 'namespace' | true  | false | false
      'private' | 'public' | 'namespace' | false | true  | false
      'private' | 'public' | 'namespace' | false | false | true
    end

    with_them do
      before do
        allow(described_class).to receive(:arkose_private_api_key).and_return(private_key)
        allow(described_class).to receive(:arkose_public_api_key).and_return(public_key)
        stub_application_setting(arkose_labs_namespace: namespace)
        allow(::Gitlab::Qa).to receive(:request?).with('user_agent').and_return(qa_request)
        create(:group_saml_identity, user: user) if group_saml_user
      end

      it { is_expected.to eq result }
    end
  end
end
