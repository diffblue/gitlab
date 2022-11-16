# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::GroupsController, feature_category: :purchase do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  describe 'GET #edit' do
    subject { get :edit, params: { id: group.to_param } }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
      end

      it { is_expected.to have_gitlab_http_status(:ok) }
    end
  end

  describe 'PUT #update' do
    subject { post :update, params: { id: group.to_param, group: params } }

    let(:params) { { name: 'New name', path: 'new-path', visibility_level: Gitlab::VisibilityLevel::PRIVATE } }

    context 'with an unauthenticated user' do
      it { is_expected.to have_gitlab_http_status(:redirect) }
      it { is_expected.to redirect_to(new_user_session_path) }
    end

    context 'with an authenticated user who is not a group owner' do
      before do
        sign_in(user)
      end

      it { is_expected.to have_gitlab_http_status(:ok) }
      it { is_expected.to render_template(:edit) }

      it 'does not update the name' do
        expect { subject }.not_to change { group.reload.name }
      end
    end

    context 'with an authenticated user' do
      before do
        sign_in(user)
        group.add_owner(user)
      end

      it 'updates the name' do
        expect { subject }.to change { group.reload.name }.to('New name')
      end

      it 'updates the path' do
        expect { subject }.to change { group.reload.path }.to('new-path')
      end

      it 'updates the visibility_level' do
        expect { subject }.to change { group.reload.visibility_level }.from(Gitlab::VisibilityLevel::PUBLIC).to(Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'redirects to the group path' do
        expect(subject).to have_gitlab_http_status(:redirect)
        expect(subject).to redirect_to('/new-path')
      end

      it 'sets flash notice' do
        subject

        expect(controller).to set_flash[:notice].to('Subscription successfully applied to "New name"')
      end

      context 'with new_user param' do
        subject { post :update, params: { id: group.to_param, group: params, new_user: 'true' } }

        it 'sets flash notice' do
          subject

          expect(controller).to set_flash[:notice].to("Welcome to GitLab, #{user.first_name}!")
        end
      end
    end

    context 'when the group cannot be saved' do
      before do
        sign_in(user)
        group.add_owner(user)
      end

      let(:params) { { name: '', path: '' } }

      it 'does not update the name' do
        expect { subject }.not_to change { group.reload.name }
      end

      it 'does not update the path' do
        expect { subject }.not_to change { group.reload.path }
      end

      it 're-renders the edit template' do
        expect(subject).to have_gitlab_http_status(:ok)
        expect(subject).to render_template(:edit)
      end
    end
  end
end
