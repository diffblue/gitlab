# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckExternalStatusChecksPassedService < CheckBaseService
      def execute
        if prevent_merge_unless_status_checks_passed?
          failure(reason: failure_reason)
        else
          success
        end
      end

      def skip?
        false
      end

      def cacheable?
        false
      end

      private

      def prevent_merge_unless_status_checks_passed?
        project = merge_request.project
        only_allow_merge_if_all_status_checks_passed_enabled?(project) &&
          project.any_external_status_checks_not_passed?(merge_request)
      end

      def only_allow_merge_if_all_status_checks_passed_enabled?(project)
        project.licensed_feature_available?(:external_status_checks) &&
          project.only_allow_merge_if_all_status_checks_passed
      end

      def failure_reason
        :status_checks_must_pass
      end
    end
  end
end
