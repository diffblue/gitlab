# frozen_string_literal: true

module ComplianceManagement
  module Standards
    module Gitlab
      class PreventApprovalByCommitterGroupWorker < GroupBaseWorker
        data_consistency :sticky
        idempotent!
        urgency :low

        feature_category :compliance_management

        def worker_class
          ::ComplianceManagement::Standards::Gitlab::PreventApprovalByCommitterWorker
        end
      end
    end
  end
end
