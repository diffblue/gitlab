# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::AddOnPurchases::BaseService, feature_category: :purchase do
  describe '#execute' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:add_on) { create(:gitlab_subscription_add_on) }

    let(:params) do
      {
        quantity: 10,
        expires_on: (Date.current + 1.year).to_s,
        purchase_xid: 'S-A00000001'
      }
    end

    subject(:result) { test_class.new(namespace, add_on, params).execute }

    context 'when execute method was not overridden' do
      let(:test_class) do
        Class.new(described_class)
      end

      it 'raises an error' do
        expect { result }.to raise_error(described_class::ImplementationMissingError)
      end
    end

    context 'when add_on_purchase method was not overridden' do
      let(:test_class) do
        Class.new(described_class) do
          def execute
            add_on_purchase
          end
        end
      end

      it 'raises an error' do
        expect { result }.to raise_error(described_class::ImplementationMissingError)
      end
    end

    context 'when add_on_purchase method was overridden' do
      let(:test_class) do
        Class.new(described_class) do
          include Gitlab::Utils::StrongMemoize

          def execute
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
