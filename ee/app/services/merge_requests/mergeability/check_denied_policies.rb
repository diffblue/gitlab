# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckDeniedPolicies < CheckBaseService
      def execute
        if merge_request.has_denied_policies?
          failure
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
    end
  end
end
