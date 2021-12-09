# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::ProjectsController do
  let_it_be(:user) { create(:user) }

  describe '#removed' do
    render_views
    subject { get :removed, format: :json }

    before do
      sign_in(user)

      allow(Kaminari.config).to receive(:default_per_page).and_return(1)
    end

    shared_examples 'returns not found' do
      it do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when licensed' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      context 'for admin users', :enable_admin_mode do
        let_it_be(:user) { create(:admin) }
        let_it_be(:projects) { create_list(:project, 2, :archived, creator: user, marked_for_deletion_at: 3.days.ago) }

        it 'returns success' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'paginates the records' do
          subject

          expect(assigns(:projects).count).to eq(1)
        end

        it 'accounts total removable projects' do
          subject

          expect(assigns(:removed_projects_count).count).to eq(2)
        end
      end

      context 'for non-admin users', :saas do
        let_it_be(:non_admin_user) { create(:user) }
        let_it_be(:ultimate_group) { create(:group_with_plan, plan: :ultimate_plan) }
        let_it_be(:premium_group) { create(:group_with_plan, plan: :premium_plan) }
        let_it_be(:no_plan_group) { create(:group_with_plan, plan: nil) }
        let_it_be(:ultimate_project) { create(:project, :archived, creator: non_admin_user, marked_for_deletion_at: 3.days.ago, namespace: ultimate_group) }
        let_it_be(:premium_project) { create(:project, :archived, creator: non_admin_user, marked_for_deletion_at: 3.days.ago, namespace: premium_group) }
        let_it_be(:no_plan_project) { create(:project, :archived, creator: non_admin_user, marked_for_deletion_at: 3.days.ago, namespace: no_plan_group) }

        before do
          sign_in(non_admin_user)
          ultimate_group.add_owner(non_admin_user)
          premium_group.add_owner(non_admin_user)
          no_plan_group.add_owner(non_admin_user)
        end

        it 'returns success' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'paginates the records' do
          subject

          expect(assigns(:projects).count).to eq(1)
        end

        it 'accounts total removable projects owned by the user on premium or above plan' do
          subject

          expect(assigns(:removed_projects_count).count).to eq(2)
        end
      end
    end

    context 'when not licensed' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      it_behaves_like 'returns not found'
    end
  end
end
