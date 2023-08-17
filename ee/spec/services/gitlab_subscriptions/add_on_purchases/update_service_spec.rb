# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::AddOnPurchases::UpdateService, :aggregate_failures, feature_category: :saas_provisioning do
  describe '#execute' do
    let_it_be(:root_namespace) { create(:group) }
    let_it_be(:add_on) { create(:gitlab_subscription_add_on) }
    let_it_be(:purchase_xid) { 'S-A00000001' }

    let(:params) do
      {
        quantity: 10,
        expires_on: (Date.current + 1.year).to_s,
        purchase_xid: purchase_xid
      }
    end

    subject(:result) { described_class.new(namespace, add_on, params).execute }

    shared_examples 'record exists' do
      context 'when a record exists' do
        let_it_be(:expires_on) { Date.current + 6.months }
        let_it_be(:add_on_purchase) do
          create(
            :gitlab_subscription_add_on_purchase,
            namespace: namespace,
            add_on: add_on,
            quantity: 5,
            expires_on: expires_on,
            purchase_xid: purchase_xid
          )
        end

        it 'returns a success' do
          expect(result[:status]).to eq(:success)
        end

        it 'updates the found record' do
          expect(result[:add_on_purchase]).to be_persisted
          expect(result[:add_on_purchase]).to eq(add_on_purchase)
          expect do
            result
            add_on_purchase.reload
          end.to change { add_on_purchase.quantity }.from(5).to(10)
            .and change { add_on_purchase.expires_on }.from(expires_on).to(params[:expires_on].to_date)
        end

        context 'when creating the record failed' do
          let(:params) { super().merge(quantity: 0) }

          it 'returns an error' do
            expect { result }.not_to change { add_on_purchase.quantity }

            expect(result[:status]).to eq(:error)
            expect(result[:message]).to eq('Add-on purchase could not be saved')
            expect(result[:add_on_purchase]).to be_an_instance_of(GitlabSubscriptions::AddOnPurchase)
            expect(result[:add_on_purchase]).to eq(add_on_purchase)
          end
        end
      end
    end

    context 'when on .com', :saas do
      let_it_be_with_reload(:namespace) { root_namespace }

      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'when no record exists' do
        it 'returns an error' do
          expect(result[:status]).to eq(:error)
          expect(result[:message]).to eq(
            "Add-on purchase for namespace #{namespace.name} and add-on #{add_on.name.titleize} does not exist, " \
            'create a new record instead'
          )
        end
      end

      include_examples 'record exists'
    end

    context 'when not on .com' do
      let_it_be(:namespace) { nil }

      context 'when no record exists' do
        it 'returns an error' do
          expect(result[:status]).to eq(:error)
          expect(result[:message]).to eq(
            "Add-on purchase for add-on #{add_on.name.titleize} does not exist, create a new record instead"
          )
        end
      end

      include_examples 'record exists'
    end
  end
end
