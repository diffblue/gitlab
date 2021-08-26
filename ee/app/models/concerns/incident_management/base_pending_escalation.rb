# frozen_string_literal: true

module IncidentManagement
  # Functionality needed for models which represent escalations.
  #
  # Implemeting classes should alias `target` to the attribute
  # of the relevant escalatable.
  #
  # EX) `alias_attribute :target, :alert`
  module BasePendingEscalation
    extend ActiveSupport::Concern

    include PartitionedTable
    include EachBatch

    ESCALATION_BUFFER = 1.month.freeze

    included do
      # Required to find records by id on partitioned tables.
      self.primary_key = :id

      partitioned_by :process_at, strategy: :monthly

      belongs_to :rule, class_name: 'EscalationRule', foreign_key: 'rule_id'

      validates :process_at, :rule_id, presence: true

      scope :processable, -> { where(process_at: ESCALATION_BUFFER.ago..Time.current) }

      delegate :project, to: :target
    end
  end
end
