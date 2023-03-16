# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # Fixes the `status` attribute of `security_scans` records
      module FixSecurityScanStatuses
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        FILTER_BY_STATUS = ->(relation) { relation.where(status: SecurityScan.statuses[:purged]) }

        prepended do
          operation_name :fix_statuses
        end

        class SecurityScan < ::ApplicationRecord # rubocop:disable Style/Documentation
          belongs_to :build, class_name: '::EE::Gitlab::BackgroundMigration::FixSecurityScanStatuses::CiBuild'

          enum status: {
            created: 0,
            succeeded: 1,
            job_failed: 2,
            report_error: 3,
            preparing: 4,
            preparation_failed: 5,
            purged: 6
          }

          def correct_status
            if has_errors?
              :report_error
            elsif ci_build_failed?
              :job_failed
            elsif artifacts_available?
              :succeeded
            else
              :purged # must be purged anyway
            end
          end

          def has_errors?
            info['errors'].present?
          end

          def ci_build_failed?
            build&.failed?
          end

          def artifacts_available?
            !build&.artifacts_expired?
          end
        end

        class CiBuild < ::Ci::ApplicationRecord # rubocop:disable Style/Documentation
          self.table_name = 'ci_builds'
          self.inheritance_column = :_type_disabled
          self.primary_key = :id

          def failed?
            status != 'success'
          end

          def artifacts_expired?
            artifacts_expire_at && artifacts_expire_at < Time.current
          end
        end

        override :perform
        def perform
          each_sub_batch(batching_scope: FILTER_BY_STATUS) do |sub_batch|
            SecurityScan.where(id: sub_batch)
                        .includes(:build)
                        .then { |scans| scans.group_by(&:correct_status) }
                        .reject { |correct_status, _| correct_status == :purged }
                        .each { |correct_status, scans| update_scans(correct_status, scans) }
          end
        end

        private

        def update_scans(status, scans)
          scan_ids = scans.map(&:id)

          SecurityScan.where(id: scan_ids).update_all(status: status)

          ::Gitlab::BackgroundMigration::Logger.info(
            class: self.class.name,
            message: "Scans are updated",
            count: scans.length,
            scan_ids: scan_ids,
            status: status
          )
        end
      end
    end
  end
end
