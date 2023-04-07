# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SetUserStatusBasedOnUserCapSettingWorker, type: :worker, feature_category: :user_profile do
  let_it_be(:active_user) { create(:user, state: 'active') }

  describe '#perform' do
    let_it_be(:user) { create(:user, :blocked_pending_approval) }

    let(:new_user_signups_cap) { 10 }

    subject { described_class.new.perform(user.id) }

    before do
      allow(Gitlab::CurrentSettings).to receive(:new_user_signups_cap).and_return(new_user_signups_cap)
    end

    shared_examples 'keeps user in blocked_pending_approval state' do
      it 'keeps the user in blocked_pending_approval state' do
        subject

        expect(user.reload).to be_blocked_pending_approval
      end
    end

    shared_examples 'sends emails to every active admin' do
      let_it_be(:active_admin) { create(:user, :admin, state: 'active') }
      let_it_be(:inactive_admin) { create(:user, :admin, :deactivated) }

      it 'sends an email to every active admin' do
        expect(::Notify).to receive(:user_cap_reached).with(active_admin.id).once.and_call_original

        subject
      end
    end

    shared_examples 'does not send emails to active admins' do
      let_it_be(:active_admin) { create(:user, :admin, state: 'active') }

      it 'does not send an email to active admins' do
        expect(::Notify).not_to receive(:user_cap_reached)

        subject
      end
    end

    context 'when user is not blocked_pending_approval' do
      let(:user) { active_user }

      it 'does nothing to the user state' do
        subject

        expect(user.reload).to be_active
      end
    end

    context 'when user cap is set to nil' do
      let(:new_user_signups_cap) { nil }

      it 'does nothing to the user state' do
        subject

        expect(user.reload).to be_blocked_pending_approval
      end

      include_examples 'does not send emails to active admins'
    end

    context 'when the auto-creation of an omniauth user is blocked' do
      before do
        allow(Gitlab.config.omniauth).to receive(:block_auto_created_users).and_return(true)
      end

      context 'when the user is an omniauth user' do
        let!(:user) { create(:omniauth_user, :blocked_pending_approval) }

        it 'does not activate this user' do
          subject

          expect(user.reload).to be_blocked
        end
      end

      context 'when the user is not an omniauth user' do
        it 'activates this user' do
          subject

          expect(user.reload).to be_active
        end
      end
    end

    context 'when current billable user count is less than user cap' do
      it 'activates the user' do
        subject

        expect(user.reload).to be_active
      end

      it 'notifies the approval to the user' do
        expect(DeviseMailer).to receive(:user_admin_approval).with(user).and_call_original
        expect { subject }.to have_enqueued_mail(DeviseMailer, :user_admin_approval)
      end

      include_examples 'does not send emails to active admins'

      context 'when user has not confirmed their email yet' do
        let(:user) { create(:user, :blocked_pending_approval, :unconfirmed) }

        it 'sends confirmation instructions' do
          expect { subject }
            .to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
        end
      end

      context 'when user has confirmed their email' do
        it 'does not send a confirmation email' do
          expect { subject }
            .not_to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
        end
      end

      context 'when the user was created via sign up' do
        it 'does not send a password reset email' do
          expect { subject }.not_to have_enqueued_mail(Notify, :new_user_email)
        end
      end

      context 'when the user was created by an admin' do
        let(:admin) { create(:user, :admin) }
        let(:user) { create(:user, :blocked_pending_approval, created_by_id: admin.id) }

        it 'sends a password reset email' do
          allow(Devise.token_generator).to receive(:generate).and_return([:reset_token, 'enc'])

          expect(Notify).to receive(:new_user_email).with(user.id, :reset_token).and_call_original

          expect { subject }.to have_enqueued_mail(Notify, :new_user_email)
        end
      end

      context 'when pending invitations' do
        let!(:project_member_invite) { create(:project_member, :invited, invite_email: user.email) }
        let!(:group_member_invite) { create(:group_member, :invited, invite_email: user.email) }

        context 'when user is unconfirmed' do
          let(:user) { create(:user, :blocked_pending_approval, :unconfirmed) }

          it 'does not accept pending invites of the user' do
            subject

            group_member_invite.reload
            project_member_invite.reload

            expect(group_member_invite).to be_invite
            expect(project_member_invite).to be_invite
          end
        end

        context 'when user is confirmed' do
          it 'accepts pending invites of the user' do
            subject

            group_member_invite.reload
            project_member_invite.reload

            expect(group_member_invite).not_to be_invite
            expect(project_member_invite).not_to be_invite
            expect(group_member_invite.user).to eq(user)
            expect(project_member_invite.user).to eq(user)
          end
        end
      end
    end

    context 'when current billable user count is equal to user cap' do
      let(:new_user_signups_cap) { 2 }

      include_examples 'keeps user in blocked_pending_approval state'
      include_examples 'sends emails to every active admin'
    end

    context 'when current billable user count is greater than user cap' do
      let_it_be(:another_active_user) { create(:user, state: 'active') }

      let(:new_user_signups_cap) { 1 }

      include_examples 'keeps user in blocked_pending_approval state'
      include_examples 'sends emails to every active admin'
    end
  end
end
