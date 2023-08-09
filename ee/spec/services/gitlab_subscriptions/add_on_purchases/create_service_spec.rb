# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::AddOnPurchases::CreateService, :aggregate_failures, feature_category: :purchase do
  describe '#execute' do
    let_it_be(:root_namespace) { create(:group) }
    let_it_be(:add_on) { create(:gitlab_subscription_add_on) }

    let(:params) do
      {
        quantity: 10,
        expires_on: (Date.current + 1.year).to_s,
        purchase_xid: 'S-A00000001'
      }
    end

    subject(:result) { described_class.new(namespace, add_on, params).execute }

    shared_examples 'no record exists' do
      context 'when no record exists' do
        it 'returns a success' do
          expect(result[:status]).to eq(:success)
        end

        it 'creates a new record' do
          expect { result }.to change { GitlabSubscriptions::AddOnPurchase.count }.by(1)

          expect(result[:add_on_purchase]).to be_persisted
          expect(result[:add_on_purchase]).to have_attributes(
            namespace: namespace,
            add_on: add_on,
            quantity: params[:quantity],
            expires_on: params[:expires_on].to_date,
            purchase_xid: params[:purchase_xid]
          )
        end

        context 'when creating the record failed' do
          let(:params) { super().merge(quantity: 0) }

          it 'returns an error' do
            expect(result[:status]).to eq(:error)
            expect(result[:message]).to eq('Add-on purchase could not be saved')
            expect(result[:add_on_purchase]).to be_an_instance_of(GitlabSubscriptions::AddOnPurchase)
            expect(result[:add_on_purchase]).not_to be_persisted
            expect(GitlabSubscriptions::AddOnPurchase.count).to eq(0)
          end
        end
      end
    end

    context 'when on .com', :saas do
      let(:namespace) { root_namespace }

      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'when passing in an empty namespace' do
        let(:namespace) { nil }

        it 'returns a success' do
          expect(result[:status]).to eq(:error)
          expect(result[:message]).to eq('No namespace given')
        end
      end

      context 'when namespace is not a root namespace' do
        let(:namespace) { create(:group, parent: root_namespace) }

        it 'returns an error' do
          expect(result[:status]).to eq(:error)
          expect(result[:message]).to eq("Namespace #{namespace.name} is not a root namespace")
        end
      end

      context 'when a record exists' do
        let!(:existing_add_on_purchase) do
          create(
            :gitlab_subscription_add_on_purchase,
            namespace: namespace,
            add_on: add_on,
            purchase_xid: params[:purchase_xid]
          )
        end

        it 'returns an error' do
          expect(result[:status]).to eq(:error)
          expect(result[:message]).to eq(
            "Add-on purchase for namespace #{namespace.name} and add-on #{add_on.name.titleize} already exists, " \
            "update the existing record"
          )
        end
      end

      include_examples 'no record exists'
    end

    context 'when not on .com' do
      let(:namespace) { nil }

      context 'when passing in a namespace that is not a root namespace' do
        let(:namespace) { create(:group, parent: root_namespace) }

        it 'returns a success' do
          expect(result[:status]).to eq(:success)
        end
      end

      context 'when a record exists' do
        let!(:existing_add_on_purchase) do
          create(
            :gitlab_subscription_add_on_purchase,
            namespace: namespace,
            add_on: add_on,
            purchase_xid: params[:purchase_xid]
          )
        end

        it 'returns an error' do
          expect(result[:status]).to eq(:error)
          expect(result[:message]).to eq(
            "Add-on purchase for add-on #{add_on.name.titleize} already exists, update the existing record"
          )
        end
      end

      include_examples 'no record exists'
    end
  end
end
