# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UnconfirmedUsersDeletionCronWorker, feature_category: :user_management do
  subject(:worker) { described_class.new }

  let_it_be_with_reload(:user_to_delete) { create(:user, :unconfirmed, created_at: cut_off_datetime - 1.day) }
  let_it_be(:unconfirmed_user_to_keep) { create(:user, :unconfirmed, created_at: cut_off_datetime + 1.day) }
  let_it_be(:confirmed_user) { create(:user, created_at: cut_off_datetime - 1.day) }
  let_it_be(:banned_user) { create(:user, :banned, :unconfirmed, created_at: cut_off_datetime - 1.day) }
  let_it_be(:bot_user) { create(:user, :bot, :unconfirmed, created_at: cut_off_datetime - 1.day) }
  let_it_be(:admin_bot) { ::User.admin_bot }

  let_it_be(:unconfirmed_user_created_after_cut_off) do
    create(:user, :unconfirmed, created_at: cut_off_datetime + 1.day)
  end

  let_it_be(:unconfirmed_user_who_signed_in) do
    create(:user, :unconfirmed, created_at: cut_off_datetime - 1.day, sign_in_count: 1)
  end

  describe '#perform', :sidekiq_inline do
    context 'when setting for deleting unconfirmed users is set' do
      before do
        stub_licensed_features(delete_unconfirmed_users: true)
        stub_application_setting(delete_unconfirmed_users: true)
        stub_application_setting(unconfirmed_users_delete_after_days: cut_off_days)
        stub_application_setting_enum('email_confirmation_setting', 'hard')
      end

      it 'destroys unconfirmed users who never signed in & signed up before unconfirmed_users_delete_after_days days' do
        admin_bot = ::User.admin_bot
        users_to_keep = [
          unconfirmed_user_created_after_cut_off,
          unconfirmed_user_who_signed_in,
          confirmed_user,
          banned_user,
          bot_user
        ]

        worker.perform

        expect(
          Users::GhostUserMigration.find_by(
            user: user_to_delete,
            initiator_user: admin_bot
          )
        ).to be_present

        users_to_keep.each do |user|
          expect(
            Users::GhostUserMigration.find_by(
              user: user,
              initiator_user: admin_bot
            )
          ).not_to be_present
        end
      end

      it 'stops after ITERATIONS of BATCH_SIZE' do
        stub_const("Users::UnconfirmedUsersDeletionCronWorker::ITERATIONS", 1)
        stub_const("Users::UnconfirmedUsersDeletionCronWorker::BATCH_SIZE", 1)
        _users_to_delete = create_list(:user, 2, :unconfirmed, created_at: cut_off_datetime - 1.day)

        expect do
          worker.perform
        end.to change { Users::GhostUserMigration.count }.by(1)
      end

      context 'when delete_unconfirmed_users license is not enabled' do
        it 'is a no-op' do
          stub_licensed_features(delete_unconfirmed_users: false)

          worker.perform

          expect(
            Users::GhostUserMigration.find_by(
              user: user_to_delete,
              initiator_user: admin_bot
            )
          ).not_to be_present
        end
      end

      context 'when email confirmation setting is off' do
        it 'is a no-op' do
          stub_application_setting_enum('email_confirmation_setting', 'off')
          worker.perform

          expect(
            Users::GhostUserMigration.find_by(
              user: user_to_delete,
              initiator_user: admin_bot
            )
          ).not_to be_present
        end
      end
    end

    context 'when setting for deleting unconfirmed users is not set' do
      before do
        stub_licensed_features(delete_unconfirmed_users: true)
        stub_application_setting(delete_unconfirmed_users: false)
        stub_application_setting(unconfirmed_users_delete_after_days: cut_off_days)
      end

      it 'is a no-op' do
        worker.perform

        expect(
          Users::GhostUserMigration.find_by(
            user: user_to_delete,
            initiator_user: admin_bot
          )
        ).not_to be_present
      end
    end
  end

  def cut_off_days
    30
  end

  def cut_off_datetime
    cut_off_days.days.ago
  end
end
