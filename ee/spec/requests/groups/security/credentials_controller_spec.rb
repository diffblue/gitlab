# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Security::CredentialsController, feature_category: :compliance_management do
  let_it_be(:group_with_managed_accounts) { create(:group_with_managed_accounts, :private) }
  let_it_be(:managed_users) { create_list(:user, 2, :group_managed, managing_group: group_with_managed_accounts) }
  let_it_be(:owner) { managed_users.first }
  let_it_be(:maintainer) { managed_users.last }
  let_it_be(:group_id) { group_with_managed_accounts.to_param }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: maintainer) }

  before do
    allow_next_instance_of(Gitlab::Auth::GroupSaml::SsoEnforcer) do |sso_enforcer|
      allow(sso_enforcer).to receive(:active_session?).and_return(true)
    end

    group_with_managed_accounts.add_owner(owner)
    group_with_managed_accounts.add_maintainer(maintainer)

    login_as(owner)
  end

  describe 'GET #index' do
    let(:filter) {}

    subject { get group_security_credentials_path(group_id: group_id.to_param, filter: filter) }

    context 'when `credentials_inventory` feature is enabled' do
      before do
        stub_licensed_features(credentials_inventory: true, group_saml: true)
      end

      context 'for a group that enforces group managed accounts' do
        context 'for a user with access to view credentials inventory' do
          it 'responds with 200' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
          end

          context 'filtering by type of credential' do
            before do
              managed_users.each do |user|
                create(:personal_access_token, user: user)
              end
            end

            shared_examples_for 'filtering by `personal_access_tokens`' do
              it do
                subject

                expect(assigns(:credentials)).to match_array(PersonalAccessToken.where(user: managed_users))
              end
            end

            context 'no credential type specified' do
              let(:filter) { nil }

              it_behaves_like 'filtering by `personal_access_tokens`'
            end

            context 'non-existent credential type specified' do
              let(:filter) { 'non_existent_credential_type' }

              it_behaves_like 'filtering by `personal_access_tokens`'
            end

            context 'credential type specified as `personal_access_tokens`' do
              let(:filter) { 'personal_access_tokens' }

              it_behaves_like 'filtering by `personal_access_tokens`'
            end

            context 'user scope' do
              it 'does not show the credentials of a user outside the group' do
                personal_access_token = create(:personal_access_token, user: create(:user))

                subject

                expect(assigns(:credentials)).not_to include(personal_access_token)
              end
            end

            context 'credential type specified as `ssh_keys`' do
              let(:filter) { 'ssh_keys' }

              before do
                managed_users.each do |user|
                  create(:personal_key, user: user)
                end
              end

              it 'filters by ssh keys' do
                subject

                expect(assigns(:credentials)).to match_array(Key.regular_keys.where(user: managed_users))
              end
            end
          end

          context 'for a user without access to view credentials inventory' do
            before do
              sign_in(maintainer)
            end

            it 'responds with 404' do
              subject

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end
      end

      context 'for a group that does not enforce group managed accounts' do
        let_it_be(:group_id) { create(:group).id }

        it 'responds with 404' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when `credentials_inventory` feature is disabled' do
      before do
        stub_licensed_features(credentials_inventory: false)
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:credentials_path) { group_security_credentials_path(filter: 'ssh_keys') }

    it_behaves_like 'credentials inventory delete SSH key', group_managed_account: true
  end

  describe 'PUT #revoke' do
    shared_examples_for 'responds with 404' do
      it do
        put revoke_group_security_credential_path(group_id: group_id.to_param, id: token_id)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    shared_examples_for 'displays the flash success message' do
      it do
        put revoke_group_security_credential_path(group_id: group_id.to_param, id: token_id)

        expect(response).to redirect_to(group_security_credentials_path)
        expect(flash[:notice]).to start_with 'Revoked personal access token '
      end
    end

    shared_examples_for 'displays the flash error message' do
      it do
        put revoke_group_security_credential_path(group_id: group_id.to_param, id: token_id)

        expect(response).to redirect_to(group_security_credentials_path)
        expect(flash[:alert]).to eql 'Not permitted to revoke'
      end
    end

    context 'when `credentials_inventory` feature is enabled' do
      before do
        stub_licensed_features(credentials_inventory: true, group_saml: true)
      end

      context 'for a group that enforces group managed accounts' do
        context 'for a user with access to view credentials inventory' do
          context 'non-existent personal access token specified' do
            let(:token_id) { 999999999999999999999999999999999 }

            it_behaves_like 'responds with 404'
          end

          describe 'with an existing personal access token' do
            context 'personal access token is already revoked' do
              let_it_be(:token_id) { create(:personal_access_token, revoked: true, user: maintainer).id }

              it_behaves_like 'displays the flash success message'
            end

            context 'personal access token is already expired' do
              let_it_be(:token_id) { create(:personal_access_token, expires_at: 5.days.ago, user: maintainer).id }

              it_behaves_like 'displays the flash success message'
            end

            context 'does not have permissions to revoke the credential' do
              let_it_be(:token_id) { create(:personal_access_token, user: create(:user)).id }

              it_behaves_like 'responds with 404'
            end

            context 'personal access token is already revoked' do
              let_it_be(:token_id) { create(:personal_access_token, revoked: true, user: maintainer).id }

              it_behaves_like 'displays the flash success message'
            end

            context 'personal access token is already expired' do
              let_it_be(:token_id) { create(:personal_access_token, expires_at: 5.days.ago, user: maintainer).id }

              it_behaves_like 'displays the flash success message'
            end

            context 'personal access token is not revoked or expired' do
              let_it_be(:token_id) { personal_access_token.id }

              it_behaves_like 'displays the flash success message'

              it 'informs the token owner' do
                expect(CredentialsInventoryMailer).to receive_message_chain(:personal_access_token_revoked_email, :deliver_later)

                put revoke_group_security_credential_path(group_id: group_id.to_param, id: personal_access_token.id)
              end
            end
          end
        end

        context 'for a user without access to view credentials inventory' do
          let_it_be(:token_id) { create(:personal_access_token, user: owner).id }

          before do
            sign_in(maintainer)
          end

          it_behaves_like 'responds with 404'
        end
      end

      context 'for a group that does not enforce group managed accounts' do
        let_it_be(:token_id) { personal_access_token.id }
        let_it_be(:group_id) { create(:group).id }

        it 'responds with 404' do
          expect do
            put revoke_group_security_credential_path(group_id: group_id.to_param, id: token_id)
          end.to raise_error(ActionController::RoutingError)
        end
      end
    end

    context 'when `credentials_inventory` feature is disabled' do
      let_it_be(:token_id) { create(:personal_access_token, user: owner).id }

      before do
        stub_licensed_features(credentials_inventory: false)
      end

      it_behaves_like 'responds with 404'
    end
  end
end
