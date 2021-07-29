# frozen_string_literal: true

module IncidentManagement
  module PendingEscalations
    class Alert < ApplicationRecord
      include PartitionedTable
      include EachBatch
      include IgnorableColumns

      ignore_columns :schedule_id, :status, remove_with: '14.4', remove_after: '2021-09-22'

      alias_attribute :target, :alert

      self.primary_key = :id
      self.table_name = 'incident_management_pending_alert_escalations'

      ESCALATION_BUFFER = 1.month.freeze

      partitioned_by :process_at, strategy: :monthly

      belongs_to :alert, class_name: 'AlertManagement::Alert', foreign_key: 'alert_id', inverse_of: :pending_escalations
      belongs_to :rule, class_name: 'EscalationRule', foreign_key: 'rule_id'

      scope :processable, -> { where(process_at: ESCALATION_BUFFER.ago..Time.current) }

      validates :process_at, presence: true
      validates :rule_id, presence: true, uniqueness: { scope: [:alert_id] }

      delegate :project, to: :alert
    end
  end
end
