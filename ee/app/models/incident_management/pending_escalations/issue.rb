# frozen_string_literal: true

module IncidentManagement
  module PendingEscalations
    class Issue < ApplicationRecord
      include ::IncidentManagement::BasePendingEscalation

      self.table_name = 'incident_management_pending_issue_escalations'

      alias_attribute :target, :issue

      belongs_to :issue, class_name: '::Issue', foreign_key: 'issue_id', inverse_of: :pending_escalations

      validates :rule_id, uniqueness: { scope: [:issue_id] }

      scope :for_target, ->(issues) { where(issue_id: issues) }

      def self.class_for_check_worker
        IssueCheckWorker
      end

      def escalatable
        issue.incident_management_issuable_escalation_status
      end

      def type
        :incident
      end
    end
  end
end
