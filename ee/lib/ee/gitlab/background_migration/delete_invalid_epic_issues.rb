# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module DeleteInvalidEpicIssues
        extend ::Gitlab::Utils::Override

        class Namespace < ActiveRecord::Base
          self.table_name = 'namespaces'

          has_many :epics
          has_many :projects
        end

        class Project < ActiveRecord::Base
          self.table_name = 'projects'

          has_many :issues
          belongs_to :group
        end

        class Epic < ActiveRecord::Base
          include EachBatch

          self.table_name = 'epics'

          has_many :epic_issues
          belongs_to :group
        end

        class Issue < ActiveRecord::Base
          self.table_name = 'issues'

          has_many :epic_issues
          belongs_to :project
        end

        class EpicIssue < ActiveRecord::Base
          self.table_name = 'epic_issues'

          belongs_to :epic
          belongs_to :issue
        end

        override :perform
        def perform(start_id, stop_id)
          to_delete = []
          epics = Epic.where(id: start_id..stop_id)
            .includes(epic_issues: { issue: :project })
            .order(:group_id)

          epics.find_in_batches do |batch|
            batch.group_by { |epic| epic.group_id }.each do |group_id, group_epics|
              groups = group_and_hierarchy(group_id)

              group_epics.each do |epic|
                next if epic.epic_issues.empty?

                epic.epic_issues.each do |epic_issue|
                  to_delete << epic_issue.id unless groups.include?(epic_issue.issue.project.namespace_id)
                end
              end
            end

            EpicIssue.where(id: to_delete).delete_all if to_delete.present?
          end
        end

        def group_and_hierarchy(id)
          ::Gitlab::ObjectHierarchy
            .new(Namespace.where(id: id))
            .base_and_ancestors.pluck(:id)
        end
      end
    end
  end
end
