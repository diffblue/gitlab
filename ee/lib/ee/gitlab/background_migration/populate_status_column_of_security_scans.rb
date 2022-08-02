# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # Backgroung migration to populate the latest column of `security_scans` records
      module PopulateStatusColumnOfSecurityScans
        UPDATE_BATCH_SIZE = 500
        UPDATE_SQL = <<~SQL
          UPDATE
            security_scans
          SET
            status = (
              CASE
                WHEN ci_builds.status = 'success' THEN 1
                ELSE 2
              END
            )
          FROM
            ci_builds
          WHERE
            ci_builds.id = security_scans.build_id AND
            security_scans.id BETWEEN %<start_id>d AND %<end_id>d
        SQL

        class SecurityScan < ActiveRecord::Base
          include EachBatch

          scope :in_range, -> (start_id, end_id) { where(id: (start_id..end_id)) }
        end

        def perform(start_id, end_id)
          log_info('Migration has been started', start_id: start_id, end_id: end_id)

          SecurityScan.in_range(start_id, end_id).each_batch(of: UPDATE_BATCH_SIZE) do |relation|
            batch_start, batch_end = relation.pick("MIN(id), MAX(id)")

            update_batch(batch_start, batch_end)
          end

          log_info('Migration has been finished', start_id: start_id, end_id: end_id)
        end

        private

        delegate :connection, to: ActiveRecord::Base, private: true
        delegate :execute, :quote, to: :connection, private: true

        def update_batch(batch_start, batch_end)
          sql = format(UPDATE_SQL, start_id: quote(batch_start), end_id: quote(batch_end))

          result = ::Gitlab::Database.allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/340017') do
            execute(sql)
          end

          log_info('Records have been updated', count: result.cmd_tuples)
        end

        def log_info(message, extra = {})
          log_payload = extra.merge(migrator: self.class.name, message: message)

          ::Gitlab::BackgroundMigration::Logger.info(**log_payload)
        end
      end
    end
  end
end
