# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::InactiveProjectsDeletionCronWorker, feature_category: :projects do
  include ProjectHelpers

  describe "#perform", :clean_gitlab_redis_shared_state, :sidekiq_inline do
    subject(:worker) { described_class.new }

    let_it_be(:admin_bot) { create(:user, :admin_bot) }
    let_it_be(:non_admin_user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:new_blank_project) do
      create_project_with_statistics.tap do |project|
        project.update!(last_activity_at: Time.current)
      end
    end

    let_it_be(:inactive_blank_project) do
      create_project_with_statistics.tap do |project|
        project.update!(last_activity_at: 13.months.ago)
      end
    end

    let_it_be(:inactive_large_project) do
      create_project_with_statistics(group, with_data: true, size_multiplier: 2.gigabytes)
        .tap { |project| project.update!(last_activity_at: 2.years.ago) }
    end

    let_it_be(:active_large_project) do
      create_project_with_statistics(group, with_data: true, size_multiplier: 2.gigabytes)
        .tap { |project| project.update!(last_activity_at: 1.month.ago) }
    end

    let_it_be(:delay) { anything }

    before do
      stub_application_setting(inactive_projects_min_size_mb: 5)
      stub_application_setting(inactive_projects_send_warning_email_after_months: 12)
      stub_application_setting(inactive_projects_delete_after_months: 14)
      stub_application_setting(deletion_adjourned_period: 7)
      stub_application_setting(delete_inactive_projects: true)
    end

    it 'does not send deletion warning email for inactive projects that are already marked for deletion' do
      inactive_large_project.update!(marked_for_deletion_at: Date.current)

      expect(::Projects::InactiveProjectsDeletionNotificationWorker).not_to receive(:perform_async)
      expect(::Projects::DestroyService).not_to receive(:new)
      expect(::Projects::MarkForDeletionService).not_to receive(:perform_in)

      worker.perform

      Gitlab::Redis::SharedState.with do |redis|
        expect(
          redis.hget('inactive_projects_deletion_warning_email_notified', "project:#{inactive_large_project.id}")
        ).to be_nil
      end
    end

    it 'invokes Projects::InactiveProjectsDeletionNotificationWorker for inactive projects and logs audit event' do
      Gitlab::Redis::SharedState.with do |redis|
        expect(redis).to receive(:hset).with(
          'inactive_projects_deletion_warning_email_notified',
          "project:#{inactive_large_project.id}",
          Date.current
        )
      end
      expect(::Projects::InactiveProjectsDeletionNotificationWorker).to receive(:perform_async).with(
        inactive_large_project.id, deletion_date).and_call_original
      expect(::Projects::DestroyService).not_to receive(:new)

      expect { worker.perform }
        .to change { AuditEvent.count }.by(1)

      expect(AuditEvent.last.details[:custom_message])
        .to eq("Project is scheduled to be deleted on #{deletion_date} due to inactivity.")
    end

    context 'when adjourned_deletion_for_projects_and_groups feature is not available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      it 'invokes Projects::DestroyService for projects that are inactive even after being notified' do
        Gitlab::Redis::SharedState.with do |redis|
          redis.hset(
            'inactive_projects_deletion_warning_email_notified',
            "project:#{inactive_large_project.id}",
            15.months.ago.to_date.to_s
          )
        end

        expect(::Projects::InactiveProjectsDeletionNotificationWorker).not_to receive(:perform_async)
        expect(::Projects::MarkForDeletionService).not_to receive(:perform_in)
        expect(::Projects::DestroyService).to receive(:new).with(inactive_large_project, admin_bot, {})
                                                           .at_least(:once).and_call_original

        worker.perform

        expect(inactive_large_project.reload.pending_delete).to eq(true)
        expect(inactive_large_project.reload.marked_for_deletion_at).to be_nil

        Gitlab::Redis::SharedState.with do |redis|
          expect(
            redis.hget('inactive_projects_deletion_warning_email_notified', "project:#{inactive_large_project.id}")
          ).to be_nil
        end
      end
    end

    context 'when adjourned_deletion_for_projects_and_groups feature is available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      shared_examples_for 'invokes Projects::DestroyService' do
        it 'invokes Projects::DestroyService' do
          Gitlab::Redis::SharedState.with do |redis|
            redis.hset(
              'inactive_projects_deletion_warning_email_notified',
              "project:#{inactive_large_project.id}",
              15.months.ago.to_date.to_s
            )
          end

          expect(::Projects::InactiveProjectsDeletionNotificationWorker).not_to receive(:perform_async)
          expect(::Projects::MarkForDeletionService).not_to receive(:perform_in)
          expect(::Projects::DestroyService).to receive(:new).with(inactive_large_project, admin_bot, {})
                                                             .at_least(:once).and_call_original

          worker.perform

          expect(inactive_large_project.reload.pending_delete).to eq(true)
          expect(inactive_large_project.reload.marked_for_deletion_at).to be_nil

          Gitlab::Redis::SharedState.with do |redis|
            expect(
              redis.hget('inactive_projects_deletion_warning_email_notified', "project:#{inactive_large_project.id}")
            ).to be_nil
          end
        end
      end

      shared_examples_for 'invokes Projects::MarkForDeletionService' do
        it 'invokes Projects::MarkForDeletionService' do
          Gitlab::Redis::SharedState.with do |redis|
            redis.hset(
              'inactive_projects_deletion_warning_email_notified',
              "project:#{inactive_large_project.id}",
              15.months.ago.to_date.to_s
            )
          end

          expect(::Projects::InactiveProjectsDeletionNotificationWorker).not_to receive(:perform_async)
          expect(::Projects::MarkForDeletionService).to receive(:new).with(inactive_large_project, admin_bot, {})
                                                                     .and_call_original

          worker.perform

          expect(inactive_large_project.reload.pending_delete).to eq(false)
          expect(inactive_large_project.reload.marked_for_deletion_at).not_to be_nil

          Gitlab::Redis::SharedState.with do |redis|
            expect(
              redis.hget('inactive_projects_deletion_warning_email_notified', "project:#{inactive_large_project.id}")
            ).to be_nil
          end
        end
      end

      context 'when adjourned_deletion_configured is not configured for the project' do
        before do
          group.namespace_settings.update!(delayed_project_removal: false)
        end

        context 'when `always_perform_delayed_deletion` is disabled' do
          before do
            stub_feature_flags(always_perform_delayed_deletion: false)
          end

          it_behaves_like 'invokes Projects::DestroyService'
        end

        context 'when `always_perform_delayed_deletion` is enabled' do
          it_behaves_like 'invokes Projects::MarkForDeletionService'
        end
      end

      context 'when adjourned_deletion_configured is configured for the project' do
        before do
          group.namespace_settings.update!(delayed_project_removal: true)
        end

        context 'when `always_perform_delayed_deletion` is disabled' do
          before do
            stub_feature_flags(always_perform_delayed_deletion: false)
          end

          it_behaves_like 'invokes Projects::MarkForDeletionService'
        end

        context 'when `always_perform_delayed_deletion` is enabled' do
          it_behaves_like 'invokes Projects::MarkForDeletionService'
        end
      end
    end
  end
end
