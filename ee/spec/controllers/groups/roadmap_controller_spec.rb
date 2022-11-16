# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Groups::RoadmapController, feature_category: :portfolio_management do
  let(:group) { create(:group, :private) }
  let(:epic)  { create(:epic, group: group) }
  let(:user)  { create(:user) }

  describe '#show' do
    context 'when the user is signed in' do
      shared_examples_for 'returns 404 status' do
        specify do
          get :show, params: { group_id: group }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      before do
        sign_in(user)
      end

      context 'when the user has access to the group' do
        before do
          group.add_developer(user)
        end

        context 'when epics feature is disabled' do
          it_behaves_like 'returns 404 status'
        end

        context 'when epics feature is enabled' do
          before do
            stub_licensed_features(epics: true)
          end

          it 'returns 200 status' do
            get :show, params: { group_id: group }

            expect(response).to have_gitlab_http_status(:ok)
          end

          context 'when roadmaps_sort is nil' do
            it 'stores roadmaps sorting param in user preference' do
              get :show, params: { group_id: group, sort: 'start_date_asc' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(user.reload.user_preference.roadmaps_sort).to eq('start_date_asc')
            end

            it 'defaults to sort_value_start_date_soon' do
              user.user_preference.update!(roadmaps_sort: nil)

              get :show, params: { group_id: group }

              expect(assigns(:sort)).to eq('start_date_asc')
            end
          end

          context 'when roadmaps_sort is present' do
            it 'update roadmaps_sort with current value' do
              user.user_preference.update!(roadmaps_sort: 'created_desc')

              get :show, params: { group_id: group, sort: 'start_date_asc' }

              expect(user.reload.user_preference.roadmaps_sort).to eq('start_date_asc')
              expect(response).to have_gitlab_http_status(:ok)
            end
          end
        end
      end

      context 'when the user does not have access to the group' do
        it_behaves_like 'returns 404 status'
      end
    end

    context 'when user is not signed in' do
      context 'when epics feature is enabled' do
        before do
          stub_licensed_features(epics: true)
        end

        context 'when anonymous users does not have access to the group' do
          it 'redirects to login page' do
            get :show, params: { group_id: group }

            expect(response).to redirect_to(new_user_session_path)
          end
        end

        context 'when anonymous users have access to the group' do
          before do
            group.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
          end

          it 'stores epics sorting param in a cookie' do
            get :show, params: { group_id: group, sort: 'start_date_asc' }

            expect(cookies['roadmap_sort']).to eq('start_date_asc')
            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end
    end
  end
end
