# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckApprovedService < CheckBaseService
      def execute
        if merge_request.approved?
          success
        else
          failure(reason: failure_reason)
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
        :not_approved
      end
    end
  end
end
