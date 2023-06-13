# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UnconfirmedUsersDeletionCronWorker, feature_category: :user_management do
  subject(:worker) { described_class.new }

  let_it_be_with_reload(:user_to_delete) { create(:user, :unconfirmed, created_at: cut_off_datetime - 1.day) }

  describe '#perform', :sidekiq_inline do
    context 'when setting for deleting unconfirmed users is set' do
      before do
        stub_licensed_features(delete_unconfirmed_users: true)
        stub_ee_application_setting(delete_unconfirmed_users: true)
        stub_ee_application_setting(unconfirmed_users_delete_after_days: cut_off_days)
      end

      it 'destroys active, unconfirmed users created before unconfirmed_users_delete_after_days days' do
        admin_bot = ::User.admin_bot

        worker.perform

        expect(
          Users::GhostUserMigration.find_by(
            user: user_to_delete,
            initiator_user: admin_bot
          )
        ).to be_present
      end

      it 'stops after ITERATIONS of BATCH_SIZE' do
        stub_const("Users::UnconfirmedUsersDeletionCronWorker::ITERATIONS", 1)
        stub_const("Users::UnconfirmedUsersDeletionCronWorker::BATCH_SIZE", 1)
        _users_to_delete = create_list(:user, 2, :unconfirmed, created_at: cut_off_datetime - 1.day)

        expect do
          worker.perform
        end.to change { Users::GhostUserMigration.count }.by(1)
      end

      context 'when delete_unconfirmed_users_setting feature is disabled' do
        it 'is a no-op' do
          stub_feature_flags(delete_unconfirmed_users_setting: false)

          worker.perform

          expect(user_to_delete.reload).not_to be_nil
        end
      end

      context 'when delete_unconfirmed_users license is not enabled' do
        it 'is a no-op' do
          stub_licensed_features(delete_unconfirmed_users: false)

          worker.perform

          expect(user_to_delete.reload).not_to be_nil
        end
      end
    end

    context 'when setting for deleting unconfirmed users is not set' do
      before do
        stub_ee_application_setting(delete_unconfirmed_users: false)
        stub_ee_application_setting(unconfirmed_users_delete_after_days: cut_off_days)
      end

      it 'is a no-op' do
        worker.perform

        expect(user_to_delete.reload).not_to be_nil
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
