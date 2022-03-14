# frozen_string_literal: true

module Deployments
  class Approval < ApplicationRecord
    self.table_name = 'deployment_approvals'

    belongs_to :deployment
    belongs_to :user

    belongs_to :approval_rule,
               class_name: 'ProtectedEnvironments::ApprovalRule',
               foreign_key: :approval_rule_id,
               inverse_of: :deployment_approvals

    validates :user, presence: true, uniqueness: { scope: :deployment_id }
    validates :deployment, presence: true
    validates :status, presence: true
    validates :comment, length: { maximum: 255 }

    enum status: {
      approved: 0,
      rejected: 1
    }
  end
end
