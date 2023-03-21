# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::UsersController, :enable_admin_mode, feature_category: :user_management do
  include AdminModeHelper

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(admin)
  end

  describe 'GET card_match' do
    context 'when not SaaS' do
      it 'responds with 404' do
        send_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when SaaS', :saas do
      context 'when user has no credit card validation' do
        it 'redirects back to #show' do
          send_request

          expect(response).to redirect_to(admin_user_path(user))
        end
      end

      context 'when user has credit card validation' do
        let!(:credit_card_validation) { create(:credit_card_validation, user: user) }
        let(:card_details) { credit_card_validation.attributes.slice(:expiration_date, :last_digits, :holder_name) }
        let!(:match) { create(:credit_card_validation, card_details) }

        it 'displays its own and matching card details' do
          send_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include(credit_card_validation.holder_name)
          expect(response.body).to include(match.holder_name)
        end
      end
    end

    def send_request
      get card_match_admin_user_path(user)
    end
  end

  describe 'GET #index' do
    it 'eager loads authorized projects association' do
      get admin_users_path

      expect(assigns(:users).first.association(:user_highest_role)).to be_loaded
      expect(assigns(:users).first.association(:elevated_members)).to be_loaded
    end
  end
end
