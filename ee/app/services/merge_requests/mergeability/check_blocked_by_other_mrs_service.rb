# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckBlockedByOtherMrsService < CheckBaseService
      def execute
        if merge_request.merge_blocked_by_other_mrs?
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
        :merge_request_blocked
      end
    end
  end
end
