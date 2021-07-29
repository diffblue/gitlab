# frozen_string_literal: true

module IncidentManagement
  class EscalationPolicy < ApplicationRecord
    self.table_name = 'incident_management_escalation_policies'

    belongs_to :project
    has_many :rules, class_name: 'EscalationRule', inverse_of: :policy, foreign_key: 'policy_id', index_errors: true
    has_many :active_rules, -> { not_removed.order(:elapsed_time_seconds, :status) }, class_name: 'EscalationRule', inverse_of: :policy, foreign_key: 'policy_id'

    validates :project_id, uniqueness: { message: _('can only have one escalation policy') }, on: :create
    validates :name, presence: true, uniqueness: { scope: [:project_id] }, length: { maximum: 72 }
    validates :description, length: { maximum: 160 }
    validates :rules, presence: true

    accepts_nested_attributes_for :rules
  end
end
