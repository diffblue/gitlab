# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PhoneVerification::TelesignCallbacksController, feature_category: :instance_resiliency do
  describe 'POST #notify' do
    subject(:do_request) { post phone_verification_telesign_callback_path }

    context 'when callback request is not valid (authentication failed)' do
      it 'returns not found status', :aggregate_failures do
        expect_next_instance_of(
          Telesign::TransactionCallback,
          an_instance_of(ActionDispatch::Request),
          an_instance_of(ActionController::Parameters)
        ) do |callback|
          expect(callback).to receive(:valid?).and_return(false)
        end

        do_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when callback request is valid' do
      it 'logs and returns ok status', :aggregate_failures do
        expect_next_instance_of(
          Telesign::TransactionCallback,
          an_instance_of(ActionDispatch::Request),
          an_instance_of(ActionController::Parameters)
        ) do |callback|
          expect(callback).to receive(:valid?).and_return(true)
          expect(callback).to receive(:log)
        end

        do_request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
