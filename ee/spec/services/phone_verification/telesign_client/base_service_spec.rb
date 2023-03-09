# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PhoneVerification::TelesignClient::BaseService, feature_category: :system_access do
  subject(:service) { described_class.new }

  describe '#execute' do
    it 'requires a subclass overrides it' do
      expect { service.execute }.to raise_error(NotImplementedError)
    end
  end

  describe '#customer_id' do
    context 'when set in application settings' do
      let(:setting_value) { 'setting_customer_id' }

      before do
        stub_application_setting(telesign_customer_xid: setting_value)
      end

      it 'is equal to the value set' do
        expect(service.customer_id).to eq(setting_value)
      end
    end

    context 'when set as in the environment variables' do
      let(:env_var_value) { 'env_var_customer_id' }

      before do
        stub_env('TELESIGN_CUSTOMER_XID', env_var_value)
      end

      it 'is equal to the value set' do
        expect(service.customer_id).to eq(env_var_value)
      end
    end

    context 'when NOT set in application settings and environment variables' do
      it 'is nil' do
        expect(service.customer_id).to eq(nil)
      end
    end
  end

  describe '#telesign_api_key' do
    context 'when set in application settings' do
      let(:setting_value) { 'setting_api_key' }

      before do
        stub_application_setting(telesign_api_key: setting_value)
      end

      it 'is equal to the value set' do
        expect(service.api_key).to eq(setting_value)
      end
    end

    context 'when set as in the environment variables' do
      let(:env_var_value) { 'env_var_api_key' }

      before do
        stub_env('TELESIGN_API_KEY', env_var_value)
      end

      it 'is equal to the value set' do
        expect(service.api_key).to eq(env_var_value)
      end
    end

    context 'when NOT set in application settings and environment variables' do
      it 'is nil' do
        expect(service.api_key).to eq(nil)
      end
    end
  end
end
