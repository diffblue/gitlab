# frozen_string_literal: true

module MergeRequests
  class SyncReportApproverApprovalRules
    include Gitlab::Allowable

    def initialize(merge_request, current_user = nil)
      @merge_request = merge_request
      @current_user = current_user
    end

    def execute(skip_authentication: false)
      return if !skip_authentication && not_allowed?

      merge_request.synchronize_approval_rules_from_target_project
    end

    private

    attr_reader :merge_request, :current_user

    def not_allowed?
      !can?(current_user, :create_merge_request_approval_rules, merge_request)
    end
  end
end
