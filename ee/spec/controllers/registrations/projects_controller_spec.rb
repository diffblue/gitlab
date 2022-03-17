# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::ProjectsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project) }

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
        it { is_expected.to have_gitlab_http_status(:not_found) }

        context 'with a namespace in the URL' do
          subject { get :new, params: { namespace_id: namespace.id } }

          it { is_expected.to have_gitlab_http_status(:not_found) }

          context 'with sufficient access' do
            before do
              namespace.add_owner(user)
            end

            it { is_expected.to have_gitlab_http_status(:ok) }
            it { is_expected.to render_template(:new) }
          end
        end
      end

      context 'when not on .com' do
        let(:com) { false }

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end
  end

  describe 'POST #create' do
    let(:combined_registration?) { false }

    it_behaves_like "Registrations::ProjectsController POST #create"
  end
end
