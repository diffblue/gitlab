# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RegistrationsController, feature_category: :system_access do
  describe '#create', :clean_gitlab_redis_rate_limiting do
    let_it_be(:base_user_params) { build_stubbed(:user).slice(:first_name, :last_name, :username, :password) }
    let_it_be(:new_user_email) { 'new@user.com' }
    let_it_be(:user_params) { { user: base_user_params.merge(email: new_user_email) } }

    before do
      stub_feature_flags(arkose_labs_signup_challenge: false)
    end

    subject { post :create, params: user_params }

    shared_examples 'blocked user by default' do
      it 'registers the user in blocked_pending_approval state' do
        subject
        created_user = User.find_by(email: new_user_email)

        expect(created_user).to be_present
        expect(created_user).to be_blocked_pending_approval
      end

      it 'does not log in the user after sign up' do
        subject

        expect(controller.current_user).to be_nil
      end

      it 'shows flash message after signing up' do
        subject

        expect(response).to redirect_to(new_user_session_path(anchor: 'login-pane'))
        expect(flash[:notice])
          .to match(/your account is awaiting approval from your GitLab administrator/)
      end
    end

    shared_examples 'active user by default' do
      it 'registers the user in active state' do
        subject
        created_user = User.find_by(email: new_user_email)

        expect(created_user).to be_present
        expect(created_user).to be_active
      end

      it 'does not show any flash message after signing up' do
        subject

        expect(flash[:notice]).to be_nil
      end
    end

    context 'when require admin approval setting is enabled' do
      before do
        stub_application_setting(require_admin_approval_after_user_signup: true)
      end

      context 'when user signup cap is set' do
        before do
          stub_application_setting(new_user_signups_cap: 3)
        end

        it_behaves_like 'blocked user by default'
      end

      context 'when user signup cap is not set' do
        before do
          stub_application_setting(new_user_signups_cap: nil)
        end

        it_behaves_like 'blocked user by default'
      end
    end

    shared_examples 'user cap handling without admin approval' do
      context 'when user signup cap is set' do
        before do
          stub_application_setting(new_user_signups_cap: 3)
        end

        context 'when user signup cap would be exceeded by new user signup' do
          let!(:users) { create_list(:user, 3) }

          it_behaves_like 'blocked user by default'
        end

        context 'when user signup cap would not be exceeded by new user signup' do
          let!(:users) { create_list(:user, 1) }

          it_behaves_like 'active user by default'
        end
      end

      context 'when user signup cap is not set' do
        before do
          stub_application_setting(new_user_signups_cap: nil)
        end

        it_behaves_like 'active user by default'
      end
    end

    context 'when require admin approval setting is disabled' do
      it_behaves_like 'user cap handling without admin approval' do
        before do
          stub_application_setting(require_admin_approval_after_user_signup: false)
        end
      end
    end

    context 'when require admin approval setting is nil' do
      it_behaves_like 'user cap handling without admin approval' do
        before do
          stub_application_setting(require_admin_approval_after_user_signup: nil)
        end
      end
    end

    context 'audit events' do
      context 'when licensed' do
        before do
          stub_licensed_features(admin_audit_log: true)
        end

        context 'when user registers for the instance' do
          it 'logs add email event and instance access request event' do
            expect { subject }.to change { AuditEvent.count }.by(2)
          end

          it 'logs the audit event info', :aggregate_failures do
            expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including({
              name: "registration_created"
            })).and_call_original

            subject

            created_user = User.find_by(email: new_user_email)
            audit_event = AuditEvent.where(author_id: created_user.id).last

            expect(audit_event).to have_attributes(
              entity: created_user,
              author: created_user,
              ip_address: created_user.current_sign_in_ip,
              attributes: hash_including({
                "target_details" => created_user.username,
                "target_id" => created_user.id,
                "target_type" => "User",
                "entity_path" => created_user.full_path
              }),
              details: hash_including({
                target_details: created_user.username,
                custom_message: "Instance access request"
              })
            )
          end

          context 'with invalid user' do
            before do
              # By creating the user beforehand, the next request
              # will be invalid (duplicate email / username)
              create(:user, **user_params[:user])
            end

            it 'does not log registration failure' do
              expect { subject }.not_to change { AuditEvent.count }
              expect(response).to render_template(:new)
            end
          end
        end
      end
    end
  end

  describe '#destroy' do
    let(:user) { create(:user) }

    before do
      user.update!(password_automatically_set: true)
      sign_in(user)
    end

    shared_examples 'it succeeds' do
      it 'succeeds' do
        post :destroy, params: { username: user.username }

        expect(flash[:notice]).to eq s_('Profiles|Account scheduled for removal.')
        expect(response).to have_gitlab_http_status(:see_other)
        expect(response).to redirect_to new_user_session_path
      end
    end

    context 'on GitLab.com when the password is automatically set' do
      before do
        stub_application_setting(password_authentication_enabled_for_web: false)
        stub_application_setting(password_authentication_enabled_for_git: false)
        allow(::Gitlab).to receive(:com?).and_return(true)
      end

      it 'redirects without deleting the account' do
        expect(DeleteUserWorker).not_to receive(:perform_async)

        post :destroy, params: { username: user.username }

        expect(flash[:alert]).to eq 'Account could not be deleted. GitLab was unable to verify your identity.'
        expect(response).to have_gitlab_http_status(:see_other)
        expect(response).to redirect_to profile_account_path
      end
    end

    context 'when license feature available' do
      before do
        stub_licensed_features(disable_deleting_account_for_users: true)
      end

      context 'when allow_account_deletion is false' do
        before do
          stub_application_setting(allow_account_deletion: false)
        end

        it 'fails with message' do
          post :destroy, params: { username: user.username }

          expect(flash[:alert]).to eq 'Account deletion is not allowed.'
          expect(response).to have_gitlab_http_status(:see_other)
          expect(response).to redirect_to profile_account_path
        end
      end

      context 'when allow_account_deletion is true' do
        before do
          stub_application_setting(allow_account_deletion: true)
        end

        include_examples 'it succeeds'
      end
    end

    context 'when license feature unavailable' do
      before do
        stub_licensed_features(disable_deleting_account_for_users: false)
      end

      context 'when allow_account_deletion is false' do
        before do
          stub_application_setting(allow_account_deletion: false)
        end

        include_examples 'it succeeds'
      end

      context 'when allow_account_deletion is true' do
        before do
          stub_application_setting(allow_account_deletion: true)
        end

        include_examples 'it succeeds'
      end
    end
  end
end
