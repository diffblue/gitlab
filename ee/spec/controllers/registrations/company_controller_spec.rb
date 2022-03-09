# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::CompanyController do
  let_it_be(:user) { create(:user) }

  describe 'GET #new' do
    subject { get :new }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      let(:com) { true }

      before do
        sign_in(user)
        allow(::Gitlab).to receive(:com?).and_return(com)
      end

      context 'when on .com' do
        it { is_expected.to have_gitlab_http_status(:ok) }
        it { is_expected.to render_template 'layouts/minimal' }
        it { is_expected.to render_template(:new) }
      end

      context 'when not on .com' do
        let(:com) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end
end
