# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::TwoFactorAuthsController, feature_category: :system_access do
  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user, provisioned_by_group_id: group.id) }

  subject(:delete_two_factor) do
    delete group_two_factor_auth_path(group_id: group.path, user_id: user.id)
  end

  before do
    sign_in(current_user)
  end

  describe 'DELETE #destroy' do
    context 'when signed in user is a group owner' do
      before do
        group.add_owner(current_user)
      end

      context 'when the user has 2FA enabled' do
        let(:user) { create(:user, :two_factor, provisioned_by_group_id: provisioned_by_group_id) }

        context 'when the user is provisioned by the current group' do
          let_it_be(:provisioned_by_group_id) { group.id }

          it 'successfully disables 2FA and redirects with a success notice', :aggregate_failures do
            delete_two_factor

            expect(user.reload.two_factor_enabled?).to eq(false)
            expect(response).to redirect_to(group_group_members_path(group))
            expect(flash[:notice])
              .to eq format(_("Two-factor authentication has been disabled successfully for %{username}!"),
                            { username: user.username })
          end

          it 'returns not found for nil user_id' do
            delete group_two_factor_auth_path(group_id: group.path, user_id: nil)

            expect(response).to have_gitlab_http_status(:not_found)
          end

          it 'returns not found for non-existent user_id' do
            delete group_two_factor_auth_path(group_id: group.path, user_id: non_existing_record_id)

            expect(response).to have_gitlab_http_status(:not_found)
          end

          it 'shows unauthorized error when group is not a root group', :aggregate_failures do
            parent = create(:group)
            subgroup = create(:group, parent: parent)
            subgroup.add_owner(current_user)

            delete group_two_factor_auth_path(group_id: subgroup.full_path, user_id: user.id)

            expect(response).to redirect_to(group_group_members_path(subgroup))
            expect(flash[:alert])
              .to eq format(_("You are not authorized to perform this action"))
          end
        end

        context 'when user is not provisioned by current group' do
          let_it_be(:provisioned_by_group_id) { create(:group) }

          it 'fails with unauthorized error', :aggregate_failures do
            delete_two_factor

            expect(response).to redirect_to(group_group_members_path(group))
            expect(flash[:alert])
              .to eq format(_("You are not authorized to perform this action"))
          end
        end
      end

      context 'when the user does not have 2FA enabled' do
        let_it_be(:user) { create(:user, provisioned_by_group_id: group.id) }

        it 'redirects to group_group_members_path' do
          delete_two_factor

          expect(response).to redirect_to(group_group_members_path(group))
        end

        it 'displays an alert on failure' do
          delete_two_factor

          expect(flash[:alert])
            .to eq _('Two-factor authentication is not enabled for this user')
        end
      end
    end

    context 'when signed in user is not a group owner' do
      context 'when the user has 2FA enabled' do
        let(:user) { create(:user, :two_factor, provisioned_by_group_id: group.id) }

        it 'responds with a 404' do
          group.add_maintainer(current_user)

          delete_two_factor

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context 'when signed in user is not a group member' do
          it 'responds with a 404' do
            delete_two_factor

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context "when invalid group id is passed" do
          def delete_two_factor_invalid_group
            delete group_two_factor_auth_path(group_id: 'non_existent_group', user_id: user.id)
          end

          it 'throws routing error' do
            expect { delete_two_factor_invalid_group }.to raise_error(ActionController::RoutingError)
          end
        end
      end
    end
  end
end
