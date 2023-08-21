# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::AddOnPurchases::SelfManaged::ProvisionCodeSuggestionsService,
  :aggregate_failures, feature_category: :sm_provisioning do
  describe '#execute' do
    let_it_be(:add_on) { create(:gitlab_subscription_add_on) }

    let!(:current_license) do
      create_current_license(
        cloud_licensing_enabled: true,
        restrictions: { code_suggestions_seat_count: purchased_add_on_quantity, subscription_name: subscription_name }
      )
    end

    let(:expires_at) { Date.current + 6.months }
    let(:purchased_add_on_quantity) { 5 }
    let(:subscription_name) { 'A-S00000002' }

    subject(:result) { described_class.new.execute }

    shared_examples 'empty success response' do
      it 'returns a success' do
        expect(result[:status]).to eq(:success)
        expect(result[:add_on_purchase]).to eq(nil)
      end
    end

    shared_examples 'handle error' do |service_class|
      it 'logs and returns an error' do
        allow_next_instance_of(service_class) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'Something went wrong'))
        end

        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Error syncing subscription add-on purchases. Message: Something went wrong')
      end
    end

    shared_examples 'expire add-on purchase' do
      context 'with existing add-on purchase' do
        let_it_be(:expiration_date) { Date.current + 3.months }
        let_it_be(:existing_add_on_purchase) do
          create(
            :gitlab_subscription_add_on_purchase,
            namespace: nil,
            add_on: add_on,
            expires_on: expiration_date
          )
        end

        it 'does not call any service to create or update an add-on purchase' do
          expect(GitlabSubscriptions::AddOnPurchases::CreateService).not_to receive(:new)
          expect(GitlabSubscriptions::AddOnPurchases::UpdateService).not_to receive(:new)

          result
        end

        context 'when the expiration fails' do
          it_behaves_like 'handle error', GitlabSubscriptions::AddOnPurchases::SelfManaged::ExpireService
        end

        it 'expires the existing add-on purchase' do
          expect do
            result
            existing_add_on_purchase.reload
          end.to change { existing_add_on_purchase.expires_on }.from(expiration_date).to(Date.yesterday)
        end

        it_behaves_like 'empty success response'
      end

      context 'without existing add-on purchase' do
        it 'does not call any of the services to update an add-on purchase' do
          expect(GitlabSubscriptions::AddOnPurchases::CreateService).not_to receive(:new)
          expect(GitlabSubscriptions::AddOnPurchases::UpdateService).not_to receive(:new)
          expect(GitlabSubscriptions::AddOnPurchases::SelfManaged::ExpireService).not_to receive(:new)

          result
        end

        it_behaves_like 'empty success response'
      end
    end

    context 'without a current license' do
      let!(:current_license) { nil }

      it_behaves_like 'expire add-on purchase'
    end

    context 'when current license is not a cloud license' do
      let!(:current_license) do
        create_current_license(cloud_licensing_enabled: true, offline_cloud_licensing_enabled: true)
      end

      it_behaves_like 'expire add-on purchase'
    end

    context 'when current license does not contain a code suggestions add-on purchase' do
      let!(:current_license) do
        create_current_license(cloud_licensing_enabled: true, restrictions: { subscription_name: subscription_name })
      end

      it_behaves_like 'expire add-on purchase'
    end

    context 'when add-on record does not exist' do
      before do
        GitlabSubscriptions::AddOn.destroy_all # rubocop: disable Cop/DestroyAll
      end

      it 'creates the add-on record' do
        expect { result }.to change { GitlabSubscriptions::AddOn.count }.by(1)
      end
    end

    context 'when add-on purchase exists' do
      let_it_be(:existing_add_on_purchase) do
        create(
          :gitlab_subscription_add_on_purchase,
          namespace: nil,
          add_on: add_on,
          expires_on: Date.current + 3.months
        )
      end

      context 'when the update fails' do
        it_behaves_like 'handle error', GitlabSubscriptions::AddOnPurchases::UpdateService
      end

      it 'updates the existing add-on purchase' do
        expect(GitlabSubscriptions::AddOnPurchases::UpdateService).to receive(:new).and_call_original

        expect { result }.not_to change { GitlabSubscriptions::AddOnPurchase.count }

        expect(result[:status]).to eq(:success)
        expect(result[:add_on_purchase]).to have_attributes(
          id: existing_add_on_purchase.id,
          expires_on: current_license.expires_at,
          quantity: purchased_add_on_quantity,
          purchase_xid: subscription_name
        )
      end
    end

    context 'when the creation fails' do
      it_behaves_like 'handle error', GitlabSubscriptions::AddOnPurchases::CreateService
    end

    it 'creates a new add-on purchase' do
      expect(GitlabSubscriptions::AddOnPurchases::CreateService).to receive(:new).and_call_original

      expect { result }.to change { GitlabSubscriptions::AddOnPurchase.count }.by(1)

      expect(result[:status]).to eq(:success)
      expect(result[:add_on_purchase]).to have_attributes(
        expires_on: current_license.expires_at,
        quantity: purchased_add_on_quantity,
        purchase_xid: subscription_name
      )
    end
  end
end
