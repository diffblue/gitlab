# frozen_string_literal: true

module ProtectedEnvironments
  class ApprovalRule < ApplicationRecord
    include Authorizable
    include ApprovalRules::Summarizable

    self.table_name = 'protected_environment_approval_rules'

    belongs_to :protected_environment, inverse_of: :approval_rules

    has_many :deployment_approvals, class_name: 'Deployments::Approval', inverse_of: :approval_rule

    validates :access_level, allow_blank: true, inclusion: { in: ALLOWED_ACCESS_LEVELS }
    validates :required_approvals,
      numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
    validates :group_inheritance_type, inclusion: { in: GROUP_INHERITANCE_TYPE.values }
  end
end
