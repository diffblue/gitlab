# frozen_string_literal: true

module ComplianceManagement
  module Standards
    module Gitlab
      class PreventApprovalByCommitterService < BaseService
        CHECK_NAME = :prevent_approval_by_merge_request_committers

        private

        def status
          project.merge_requests_disable_committers_approval? ? :success : :fail
        end
      end
    end
  end
end
