# frozen_string_literal: true

module EE
  module Types
    module IssueSortEnum
      extend ActiveSupport::Concern

      prepended do
        value 'WEIGHT_ASC', 'Weight by ascending order.', value: 'weight_asc'
        value 'WEIGHT_DESC', 'Weight by descending order.', value: 'weight_desc'
        value 'PUBLISHED_ASC', 'Published issues shown last.', value: :published_asc
        value 'PUBLISHED_DESC', 'Published issues shown first.', value: :published_desc
        value 'SLA_DUE_AT_ASC', 'Issues with earliest SLA due time shown first.', value: :sla_due_at_asc
        value 'SLA_DUE_AT_DESC', 'Issues with latest SLA due time shown first.', value: :sla_due_at_desc
        value 'BLOCKING_ISSUES_ASC', 'Blocking issues count by ascending order.', value: :blocking_issues_asc
        value 'BLOCKING_ISSUES_DESC', 'Blocking issues count by descending order.', value: :blocking_issues_desc
        value 'HEALTH_STATUS_ASC', 'Issues with healthy issues first.', value: :health_status_asc
        value 'HEALTH_STATUS_DESC', 'Issues with unhealthy issues first.', value: :health_status_desc
      end
    end
  end
end
