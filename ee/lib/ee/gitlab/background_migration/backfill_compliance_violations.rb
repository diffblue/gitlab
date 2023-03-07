# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # This module is used to migrate data from merge_request_metrics and merge_requests table
      # to merge_requests_compliance_violations table.
      # It migrates target_project_id, title and target_branch columns from merge_requests table into
      # merge_requests_compliance_violations.
      # It also migrates merged_at column from merge_request_metrics table into merge_requests_compliance_violations.
      module BackfillComplianceViolations
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          operation_name :backfill_compliance_violations
        end

        # Migration only version of `merge_requests` table
        class MergeRequest < ::ApplicationRecord
          self.table_name = 'merge_requests'
          has_one :metrics,
            class_name: '::EE::Gitlab::BackgroundMigration::BackfillComplianceViolations::Metrics',
            inverse_of: :merge_request
        end

        # Migration only version of `merge_requests_compliance_violations` table
        class ComplianceViolation < ::ApplicationRecord
          self.table_name = 'merge_requests_compliance_violations'
          belongs_to :merge_request,
            class_name: '::EE::Gitlab::BackgroundMigration::BackfillComplianceViolations::MergeRequest'
        end

        # Migration only version of `merge_request_metrics` table
        class Metrics < ::ApplicationRecord
          self.table_name = 'merge_request_metrics'
          belongs_to :merge_request,
            class_name: '::EE::Gitlab::BackgroundMigration::BackfillComplianceViolations::MergeRequest',
            inverse_of: :metrics
        end

        override :perform
        def perform
          each_sub_batch do |sub_batch|
            update_compliance_violations(sub_batch)
          end
        end

        def update_compliance_violations(batch)
          ComplianceViolation.id_in(batch.pluck(:id)).includes(merge_request: [:metrics]).each do |violation|
            merge_request = violation.merge_request
            violation.assign_attributes(
              {
                title: merge_request.title,
                target_branch: merge_request.target_branch,
                target_project_id: merge_request.target_project_id,
                merged_at: merge_request.metrics&.merged_at
              })
            violation.save!(touch: false)
          end
        end
      end
    end
  end
end
