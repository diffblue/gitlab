# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ServiceAccounts::CreateService, feature_category: :user_management do
  shared_examples 'service account creation failure' do
    it 'produces an error', :aggregate_failures do
      result = described_class.new(current_user).execute

      expect(result.status).to eq(:error)
      expect(result.message).to eq(_('ServiceAccount|User does not have permission to create a service account.'))
    end
  end

  subject(:service) { described_class.new(current_user) }

  context 'when current user is an admin ', :enable_admin_mode do
    let_it_be(:current_user) { create(:admin) }

    it_behaves_like 'service account creation failure'

    context 'when the feature is available' do
      before do
        stub_licensed_features(service_accounts: true)
      end

      it_behaves_like 'service account creation success' do
        let(:username_prefix) { 'service_account' }
      end

      it 'correctly returns active model errors' do
        service = described_class.new(current_user)
        service.execute

        result = service.execute

        expect(result.status).to eq(:error)
        expect(result.message).to eq('Email has already been taken and Username has already been taken')
      end
    end
  end

  context 'when the current user is not an admin' do
    let_it_be(:current_user) { create(:user) }

    before do
      stub_licensed_features(service_accounts: true)
    end

    it_behaves_like 'service account creation failure'
  end
end
