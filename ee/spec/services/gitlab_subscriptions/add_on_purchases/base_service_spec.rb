# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::AddOnPurchases::BaseService, feature_category: :saas_provisioning do
  describe '#execute' do
    let_it_be(:admin) { build(:user, :admin) }
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:add_on) { create(:gitlab_subscription_add_on) }

    let(:params) do
      {
        quantity: 10,
        expires_on: (Date.current + 1.year).to_s,
        purchase_xid: 'S-A00000001'
      }
    end

    let(:test_class) do
      Class.new(described_class) do
        def execute
          super

          add_on_purchase
        end
      end
    end

    subject(:result) { test_class.new(user, namespace, add_on, params).execute }

    context 'with a non-admin user' do
      let(:non_admin) { build(:user) }
      let(:user) { non_admin }

      it 'raises an error' do
        expect { result }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'with an admin user' do
      let(:user) { admin }

      context 'when add_on_purchase method was not overridden' do
        it 'raises an error' do
          expect { result }.to raise_error(described_class::ImplementationMissingError)
        end
      end

      context 'when add_on_purchase method was overridden' do
        let(:test_class) do
          Class.new(described_class) do
            include Gitlab::Utils::StrongMemoize

            def execute
              super

              add_on_purchase.save ? successful_response : error_response
            end

            private

            def add_on_purchase
              @add_on_purchase ||= GitlabSubscriptions::AddOnPurchase.new(
                namespace: namespace,
                add_on: add_on,
                quantity: quantity,
                expires_on: expires_on,
                purchase_xid: purchase_xid
              )
            end
          end
        end

        context 'with success response' do
          it 'returns a success' do
            expect(result[:status]).to eq(:success)
            expect(result[:add_on_purchase]).to be_present
          end
        end

        context 'with error response' do
          let(:params) { super().merge(quantity: 0) }

          it 'returns an error' do
            expect(result[:status]).to eq(:error)
            expect(result[:message]).to eq('Add-on purchase could not be saved')
            expect(result[:add_on_purchase]).to be_present
          end
        end
      end
    end
  end
end
