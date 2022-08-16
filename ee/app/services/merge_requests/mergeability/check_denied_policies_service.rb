# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckDeniedPoliciesService < CheckBaseService
      def execute
        if merge_request.has_denied_policies?
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

      def failure_reason
        :policies_denied
      end
    end
  end
end
