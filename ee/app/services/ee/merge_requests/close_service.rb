# frozen_string_literal: true

module EE
  module MergeRequests
    module CloseService
      def expire_unapproved_key(merge_request)
        merge_request.approval_state.expire_unapproved_key!
      end
    end
  end
end
