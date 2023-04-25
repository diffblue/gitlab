# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::TanukiBotController, feature_category: :global_search do
  describe 'GET #ask' do
    let(:question) { 'Some question' }

    subject { post :ask, params: { q: question }, format: :json }

    before do
      allow(Gitlab::Llm::TanukiBot).to receive_message_chain(:new, :execute).and_return({})
      allow(Gitlab::Llm::TanukiBot).to receive(:enabled_for?).and_return(true)
    end

    it 'responds with a 401' do
      subject

      expect(response).to have_gitlab_http_status(:unauthorized)
    end

    context 'when the user is signed in' do
      before do
        sign_in(create(:user))
      end

      context 'when user does not have access to the feature' do
        before do
          allow(Gitlab::Llm::TanukiBot).to receive(:enabled_for?).and_return(false)
        end

        it 'responds with a 401' do
          subject

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      it 'responds with :bad_request if the request is not json' do
        post :ask, params: { q: question }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'responds with :ok' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'calls TanukiBot service' do
        expect(Gitlab::Llm::TanukiBot).to receive_message_chain(:new, :execute)

        subject
      end

      context 'when question is not provided' do
        let(:question) { nil }

        it 'raises an error' do
          expect { subject }.to raise_error(ActionController::ParameterMissing)
        end
      end
    end
  end
end
