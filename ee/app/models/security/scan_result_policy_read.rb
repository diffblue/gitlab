# frozen_string_literal: true

module Security
  class ScanResultPolicyRead < ApplicationRecord
    include EachBatch

    self.table_name = 'scan_result_policies'

    belongs_to :security_orchestration_policy_configuration, class_name: 'Security::OrchestrationPolicyConfiguration'
    has_many :software_license_policies

    validates :match_on_inclusion, inclusion: { in: [true, false], message: 'must be a boolean value' }
    validates :role_approvers, inclusion: { in: Gitlab::Access.all_values }

    def newly_detected?
      license_states.include?(ApprovalProjectRule::NEWLY_DETECTED)
    end
  end
end
