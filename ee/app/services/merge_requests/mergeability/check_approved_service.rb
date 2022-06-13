# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckApprovedService < CheckBaseService
      def execute
        if merge_request.approved?
          success
        else
          failure
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
