# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubscriptionsController, :clean_gitlab_redis_sessions, feature_category: :purchase do
  include SessionHelpers

  shared_examples 'requires authentication' do
    it 'requires authentication' do
      subject
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  shared_examples 'skips authenticate_user! when undergoing identity verification' do
    it_behaves_like 'requires authentication'

    context 'when user is undergoing identity verification' do
      let_it_be(:unverified_user) { create(:user) }

      before do
        stub_session(verification_user_id: unverified_user.id)
      end

      it 'skips authentication' do
        subject
        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when user has verified a credit card' do
        let!(:credit_card) { create(:credit_card_validation, user: unverified_user) }

        it_behaves_like 'requires authentication'
      end
    end
  end

  describe 'GET /payment_form' do
    before do
      allow(Gitlab::SubscriptionPortal::Client)
        .to receive(:payment_form_params)
        .and_return({ data: {} })
    end

    subject { get payment_form_subscriptions_path }

    include_examples 'skips authenticate_user! when undergoing identity verification'
  end

  describe 'POST /validate_payment_method' do
    before do
      allow(Gitlab::SubscriptionPortal::Client)
        .to receive(:validate_payment_method)
        .and_return({})
    end

    subject { post validate_payment_method_subscriptions_path }

    include_examples 'skips authenticate_user! when undergoing identity verification'
  end
end
