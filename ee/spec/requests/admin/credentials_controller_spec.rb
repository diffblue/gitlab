# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::CredentialsController, type: :request do
  include AdminModeHelper

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:project_bot) { create(:user, :project_bot, created_by_id: user.id) }
  let_it_be(:project_member) { create(:project_member, user: project_bot) }
  let_it_be(:project_access_token) { create(:personal_access_token, user: project_member.user) }

  describe 'GET #index' do
    context 'admin user' do
      before do
        login_as(admin)
        enable_admin_mode!(admin)
      end

      context 'when `credentials_inventory` feature is enabled' do
        before do
          stub_licensed_features(credentials_inventory: true)
        end

        it 'responds with 200' do
          get admin_credentials_path

          expect(response).to have_gitlab_http_status(:ok)
        end

        describe 'filtering by type of credential' do
          let_it_be(:personal_access_tokens) { create_list(:personal_access_token, 2, user: user) }

          shared_examples_for 'filtering by `personal_access_tokens`' do
            specify do
              get admin_credentials_path(filter: filter)

              expect(assigns(:credentials)).to match_array([user.personal_access_tokens, project_access_token].flatten)
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

          context 'credential type specified as `ssh_keys`' do
            it 'filters by ssh keys' do
              ssh_keys = create_list(:personal_key, 2, user: user)

              get admin_credentials_path(filter: 'ssh_keys')

              expect(assigns(:credentials)).to match_array(ssh_keys)
            end
          end

          context 'credential type specified as `project_access_tokens`' do
            it 'filters by project access tokens' do
              get admin_credentials_path(filter: 'project_access_tokens')

              expect(assigns(:credentials)).to contain_exactly(project_access_token)
            end
          end

          context 'credential type specified as `gpg_keys`' do
            it 'filters by gpg keys' do
              gpg_key = create(:gpg_key)

              get admin_credentials_path(filter: 'gpg_keys')

              expect(assigns(:credentials)).to match_array([gpg_key])
            end

            # There is currently N+1 issue when checking verified_emails per user:
            # https://gitlab.com/gitlab-org/gitlab/-/issues/322773
            # Therefore we are currently adding + 1 to the control until this is resolved
            it 'avoids N+1 queries' do
              control_user = create(:user, name: 'User Name', email: GpgHelpers::User1.emails.first)
              new_user = create(:user, name: 'User Name', email: GpgHelpers::User2.emails.first)

              create(:gpg_key, user: control_user, key: GpgHelpers::User1.public_key)
              create(:gpg_key, user: control_user, key: GpgHelpers::User1.public_key2)

              get admin_credentials_path(filter: 'gpg_keys')

              control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
                get admin_credentials_path(filter: 'gpg_keys')
              end.count

              create(:gpg_key, user: new_user, key: GpgHelpers::User2.public_key)

              expect do
                get admin_credentials_path(filter: 'gpg_keys')
              end.not_to exceed_query_limit(control + 1)
            end
          end
        end
      end

      context 'when `credentials_inventory` feature is disabled' do
        before do
          stub_licensed_features(credentials_inventory: false)
        end

        it 'returns 404' do
          get admin_credentials_path

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'non-admin user' do
      before do
        login_as(user)
      end

      it 'returns 404' do
        get admin_credentials_path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:credentials_path) { admin_credentials_path(filter: 'ssh_keys') }

    it_behaves_like 'credentials inventory delete SSH key'
  end

  describe 'PUT #revoke' do
    let_it_be(:project_member) { create(:project_member) }
    let_it_be(:project_access_token) { create(:personal_access_token, user: project_member.user) }

    let(:project) { project_member.project }

    shared_examples_for 'responds with 404' do
      it do
        put revoke_admin_credential_path(id: token_id)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it do
        put admin_credential_project_revoke_path(credential_id: token_id, project_id: project.id)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    shared_examples_for 'displays the flash success message' do
      it do
        put revoke_admin_credential_path(id: token_id)

        expect(response).to redirect_to(admin_credentials_path)
        expect(flash[:notice]).to start_with 'Revoked personal access token '
      end

      it :aggregate_failures do
        put admin_credential_project_revoke_path(credential_id: project_access_token.id, project_id: project.id)

        expect(response).to redirect_to(admin_credentials_path)
        expect(flash[:notice]).to eq "Access token #{project_access_token.name} has been revoked and the bot user has been scheduled for deletion."
      end
    end

    shared_examples_for 'displays the flash error message' do
      it do
        put revoke_admin_credential_path(id: token_id)

        expect(response).to redirect_to(admin_credentials_path)
        expect(flash[:alert]).to eql 'Not permitted to revoke'
      end
    end

    context 'admin user' do
      before do
        login_as(admin)
        enable_admin_mode!(admin)
      end

      context 'when `credentials_inventory` feature is enabled' do
        before do
          stub_licensed_features(credentials_inventory: true)
        end

        context 'non-existent personal access token specified' do
          let(:token_id) { 999999999999999999999999999999999 }

          it_behaves_like 'responds with 404'
        end

        describe 'with an existing personal access token' do
          context 'does not have permissions to revoke the credential' do
            before do
              allow(Ability).to receive(:allowed?).with(admin, :log_in, :global) { true }
              allow(Ability).to receive(:allowed?).with(admin, :revoke_token, personal_access_token) { false }
              allow(Ability).to receive(:allowed?).with(admin, :update_name, admin).and_call_original
            end

            let(:token_id) { personal_access_token.id }

            it_behaves_like 'displays the flash error message'
          end

          context 'personal access token is already revoked' do
            let_it_be(:token_id) { create(:personal_access_token, revoked: true, user: user).id }

            it_behaves_like 'displays the flash success message'
          end

          context 'personal access token is already expired' do
            let_it_be(:token_id) { create(:personal_access_token, expires_at: 5.days.ago, user: user).id }

            it_behaves_like 'displays the flash success message'
          end

          context 'personal access token is not revoked or expired' do
            let(:token_id) { personal_access_token.id }

            it_behaves_like 'displays the flash success message'

            it 'informs the token owner' do
              expect(CredentialsInventoryMailer).to receive_message_chain(:personal_access_token_revoked_email, :deliver_later)

              put revoke_admin_credential_path(id: personal_access_token.id)
            end
          end
        end
      end

      context 'when `credentials_inventory` feature is disabled' do
        before do
          stub_licensed_features(credentials_inventory: false)
        end

        let(:token_id) { personal_access_token.id }

        it_behaves_like 'responds with 404'
      end
    end

    context 'non-admin user' do
      before do
        login_as(user)
      end

      let(:token_id) { personal_access_token.id }

      it_behaves_like 'responds with 404'
    end
  end
end

RSpec.describe Admin::CredentialsController, type: :controller do
  include AdminModeHelper

  let_it_be(:admin) { create(:admin) }

  before do
    stub_licensed_features(credentials_inventory: true)
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  it_behaves_like 'tracking unique visits', :index do
    let(:target_id) { 'i_compliance_credential_inventory' }
  end
end
