# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::Verification do
  controller(ActionController::Base) do
    include Registrations::Verification

    before_action :set_requires_verification, only: :new

    def index
      head :ok
    end

    def create
      head :ok
    end

    def new
      head :ok
    end

    def html_request?
      request.format.html?
    end
  end

  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe '#require_verification' do
    describe 'verification is not required' do
      it 'does not redirect' do
        get :index

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    describe 'verification is required' do
      let_it_be(:user) { create(:user, requires_credit_card_verification: true) }

      it 'redirects to the new users sign_up groups_project path' do
        get :index

        expect(response).to redirect_to(new_users_sign_up_groups_project_path)
      end

      it 'does not redirect on JS requests' do
        get :index, format: :js

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'does not redirect on POST requests' do
        post :create

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe '#set_requires_verification' do
    it 'sets the requires_credit_card_verification attribute' do
      expect { get :new }.to change { user.reload.requires_credit_card_verification }.to(true)
    end

    context 'when a credit card validation exists' do
      before do
        create(:credit_card_validation, user: user)
      end

      it 'does not change the requires_credit_card_verification attribute' do
        expect { get :new }.not_to change { user.reload.requires_credit_card_verification }
      end
    end
  end
end
