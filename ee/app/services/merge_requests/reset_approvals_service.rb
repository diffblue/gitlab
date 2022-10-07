# frozen_string_literal: true

module MergeRequests
  class ResetApprovalsService < ::MergeRequests::BaseService
    def execute(ref, newrev, skip_reset_checks: false)
      reset_approvals_for_merge_requests(ref, newrev, skip_reset_checks)
    end

    private

    # Note: Closed merge requests also need approvals reset.
    def reset_approvals_for_merge_requests(ref, newrev, skip_reset_checks = false)
      branch_name = ::Gitlab::Git.ref_name(ref)
      merge_requests = merge_requests_for(branch_name, mr_states: [:opened, :closed])

      merge_requests.each do |merge_request|
        if skip_reset_checks
          # Delete approvals immediately, with no additional checks or side-effects
          #
          delete_approvals(merge_request)
        else
          reset_approvals(merge_request, newrev)
        end
      end
    end

    def reset_approvals?(merge_request, newrev)
      super && merge_request.rebase_commit_sha != newrev
    end
  end
end
