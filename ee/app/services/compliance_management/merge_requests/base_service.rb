# frozen_string_literal: true

module ComplianceManagement
  module MergeRequests
    class BaseService
      include BaseServiceUtility

      def initialize(merge_request)
        @merge_request = merge_request
      end
    end
  end
end
