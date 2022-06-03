# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # Class that removes invalid records from `epic_issues` table.
      # For more information check: https://gitlab.com/gitlab-org/gitlab/-/issues/339514
      module DeleteInvalidEpicIssues
        extend ::Gitlab::Utils::Override
        class Namespace < ::ApplicationRecord
          self.table_name = 'namespaces'
          self.inheritance_column = :_type_disabled

          has_many :epics
          has_many :projects

          SELF_AND_DESCENDANTS = <<~SQL
            SELECT namespaces.id
              FROM namespaces
              WHERE namespaces.type = 'Group' AND (traversal_ids @> ('{%{id}}'))
          SQL

          def self_with_descendants_ids
            formatted_query = format(SELF_AND_DESCENDANTS, id: self.id)

            namespaces = ::ApplicationRecord.connection.execute(formatted_query)
            namespaces.to_a.collect { |h| h['id'] }
          end
        end

        class Project < ::ApplicationRecord
          self.table_name = 'projects'

          has_many :issues
          belongs_to :group
        end

        class Epic < ::ApplicationRecord
          include EachBatch

          self.table_name = 'epics'

          has_many :epic_issues
          belongs_to :group
        end

        class Issue < ::ApplicationRecord
          self.table_name = 'issues'

          has_many :epic_issues
          belongs_to :project
        end

        class EpicIssue < ::ApplicationRecord
          self.table_name = 'epic_issues'

          belongs_to :epic
          belongs_to :issue
        end

        override :perform
        def perform
          batch_relation = Epic.where(id: start_id..end_id).order(:group_id)

          find_and_delete_invalid_records(batch_relation, sub_batch_size, pause_ms)
        end

        private

        # rubocop:disable Layout/LineLength
        def find_and_delete_invalid_records(epics, sub_batch_size, pause)
          epics.each_batch(of: sub_batch_size) do |sub_batch|
            to_be_deleted = []
            batch = sub_batch.joins(epic_issues: { issue: :project })
                             .select('epics.group_id as group_id, epic_issues.id as epic_issue_id, projects.namespace_id as issue_namespace_id')

            batch.group_by(&:group_id).each do |group_id, group_epics|
              group_hierarchy_ids = Namespace.find_by(id: group_id)&.self_with_descendants_ids
              next if group_hierarchy_ids.blank?

              group_epics.each do |epic|
                next if group_hierarchy_ids.include?(epic.issue_namespace_id)

                to_be_deleted << epic.epic_issue_id
              end
            end

            delete_records(to_be_deleted)
            pause = 0 if pause < 0
            sleep(pause * 0.001)
          end
        end
        # rubocop:enable Layout/LineLength

        def delete_records(records)
          return unless records.present?

          to_delete = EpicIssue.where(id: records)
          log_info('Removing EpicIssue records', deleted_count: to_delete.size, data: to_delete.map(&:attributes))

          batch_metrics.time_operation(:delete_all) { to_delete.delete_all }
        end

        def logger
          @logger ||= ::Gitlab::BackgroundMigration::Logger.build
        end

        def log_info(message, **extra)
          logger.info(migrator: 'DeleteInvalidEpicIssues', message: message, **extra)
        end

        def batch_metrics
          @batch_metrics ||= ::Gitlab::Database::BackgroundMigration::BatchMetrics.new
        end
      end
    end
  end
end
