# frozen_string_literal: true

module Quality
  class TestGroupCleanupProdWorker
    include ApplicationWorker

    data_consistency :always
    feature_category :quality_management
    urgency :low

    include CronjobQueue
    idempotent!

    QA_USER_IN_PRODUCTION = 'gitlab-qa'

    # This is a temporary workaround for issue https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82692
    # Consolidates the logic with quality::test_data_cleanup_worker once we enforce the naming schema for test data
    # rubocop: disable CodeReuse/ActiveRecord
    def perform
      return unless Gitlab.com?
      return unless (qa_user_id = User.find_by(username: QA_USER_IN_PRODUCTION)&.id).present?

      Group.joins(:all_group_members).where(members: { user_id: qa_user_id }).find_each do |group|
        with_context(namespace: group, user: group.owners.first) do
          Groups::DestroyService.new(group, group.owners.first).execute if group.marked_for_deletion?
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
