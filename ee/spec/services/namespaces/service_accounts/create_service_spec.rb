# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::ServiceAccounts::CreateService, feature_category: :user_management do
  shared_examples 'service account creation failure' do
    it 'produces an error', :aggregate_failures do
      result = service.execute

      expect(result.status).to eq(:error)
      expect(result.message).to eq(
        _('ServiceAccount|User does not have permission to create a service account in this namespace.')
      )
    end
  end

  let_it_be(:group) { create(:group) }

  subject(:service) { described_class.new(current_user, { namespace_id: group.id }) }

  context 'when current user is an owner' do
    let_it_be(:current_user) { create(:user).tap { |user| group.add_owner(user) } }

    it_behaves_like 'service account creation failure'

    context 'when the feature is available' do
      before do
        stub_licensed_features(service_accounts: true)
      end

      it_behaves_like 'service account creation success' do
        let(:username_prefix) { "service_account_group_#{group.id}" }
      end

      it 'sets provisioned by group' do
        result = service.execute

        expect(result.payload.provisioned_by_group_id).to eq(group.id)
      end

      context 'when the group is invalid' do
        subject(:service) { described_class.new(current_user, { namespace_id: non_existing_record_id }) }

        it_behaves_like 'service account creation failure'
      end
    end
  end

  context 'when the current user is not an owner' do
    let_it_be(:current_user) { create(:user).tap { |user| group.add_maintainer(user) } }

    before do
      stub_licensed_features(service_accounts: true)
    end

    it_behaves_like 'service account creation failure'
  end
end
