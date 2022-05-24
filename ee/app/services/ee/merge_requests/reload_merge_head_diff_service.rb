# frozen_string_literal: true

module EE
  module MergeRequests
    module ReloadMergeHeadDiffService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        super.tap do |response|
          next unless response[:status] == :success
          next unless merge_request.project.licensed_feature_available?(:code_owners)
          next if merge_request.on_train?

          sync_code_owner_approval_rules
        end
      end

      private

      def sync_code_owner_approval_rules
        ::MergeRequests::SyncCodeOwnerApprovalRules.new(merge_request).execute
      end
    end
  end
end
