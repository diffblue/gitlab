# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::SubscriptionsController, :cloud_licenses, feature_category: :purchase do
  include AdminModeHelper

  describe 'GET /subscriptions' do
    context 'when the user is not admin' do
      let_it_be(:user) { create(:user) }

      it 'responds with 404' do
        sign_in(user)

        send_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user an admin' do
      let_it_be(:admin) { create(:admin) }

      before do
        login_as(admin)
        enable_admin_mode!(admin)
      end

      it 'renders the Activation Form' do
        send_request

        expect(response).to render_template(:show)
        expect(response.body).to include('js-show-subscription-page')
      end
    end
  end

  def send_request
    get admin_subscription_path
  end
end
