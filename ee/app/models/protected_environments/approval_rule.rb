# frozen_string_literal: true

module ProtectedEnvironments
  class ApprovalRule < ApplicationRecord
    include Authorizable

    self.table_name = 'protected_environment_approval_rules'

    belongs_to :protected_environment, inverse_of: :approval_rules

    has_many :deployment_approvals, class_name: 'Deployments::Approval', inverse_of: :approval_rule

    validates :access_level, allow_blank: true, inclusion: { in: ALLOWED_ACCESS_LEVELS }
  end
end
