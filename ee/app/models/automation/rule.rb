# frozen_string_literal: true

module Automation
  class Rule < ApplicationRecord
    include TriggerableHooks
    include StripAttribute

    FAILURE_THRESHOLD = 3
    EXCEEDED_FAILURE_THRESHOLD = FAILURE_THRESHOLD + 1

    self.table_name = 'automation_rules'

    triggerable_hooks [
      :issue_hooks,
      :merge_request_hooks
    ]

    scope :executable, -> { where(permanently_disabled: false) }

    belongs_to :namespace, inverse_of: :automation_rules, optional: false

    strip_attributes! :name

    validates :name,
      presence: true,
      length: { maximum: 255 },
      uniqueness: { case_sensitive: false, scope: [:namespace_id] }
  end
end
