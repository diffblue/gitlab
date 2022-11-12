# frozen_string_literal: true

module MergeRequests
  class DeleteBranchWorker
    include ApplicationWorker

    data_consistency :always

    feature_category :source_code_management
    urgency :high
    idempotent!

    def perform(merge_request_id, user_id, branch_name, retarget_branch)
      merge_request = MergeRequest.find_by_id(merge_request_id)
      user = User.find_by_id(user_id)

      return unless merge_request.present? && user.present?
      return unless merge_request.source_project.repository.branch_exists?(branch_name)

      delete_service_result = ::Branches::DeleteService.new(merge_request.source_project, user)
        .execute(branch_name)

      if retarget_branch
        ::MergeRequests::RetargetChainService.new(project: merge_request.source_project, current_user: user)
          .execute(merge_request)
      end

      return unless Feature.enabled?(:track_and_raise_delete_source_errors,
                                        merge_request.source_project)

      delete_service_result.track_and_raise_exception
    end
  end
end
