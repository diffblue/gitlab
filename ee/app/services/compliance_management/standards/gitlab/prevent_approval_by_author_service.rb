# frozen_string_literal: true

module ComplianceManagement
  module Standards
    module Gitlab
      class PreventApprovalByAuthorService < BaseService
        CHECK_NAME = :prevent_approval_by_merge_request_author

        private

        def status
          project.merge_requests_author_approval? ? :fail : :success
        end
      end
    end
  end
end
