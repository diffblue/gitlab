# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersController do
  let_it_be(:user) { create(:user) }
  let_it_be(:another_user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #available_project_templates', feature_category: :source_code_management do
    context 'a user requests templates for themselves' do
      it 'responds successfully' do
        get :available_project_templates, params: { username: user.username }, xhr: true

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq 'text/html'
      end
    end

    context 'a user requests templates for another user' do
      it 'responds with not found error' do
        get :available_project_templates, params: { username: another_user.username }, xhr: true

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #available_group_templates', feature_category: :user_profile do
    context 'a user requests templates for themselves' do
      it 'responds successfully' do
        get :available_group_templates, params: { username: user.username }, xhr: true

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq 'text/html'
      end
    end

    context 'a user requests templates for another user' do
      it 'responds with not found error' do
        get :available_group_templates, params: { username: another_user.username }, xhr: true

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
