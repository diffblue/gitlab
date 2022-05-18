# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # Migrate requirements to work items(issues of requirement type)
      # Eventually Requirement objects will be deprecated
      # For more information check: https://gitlab.com/gitlab-org/gitlab/-/issues/323779#completion
      module MigrateRequirementsToWorkItems
        extend ::Gitlab::Utils::Override

        SYNC_PARAMS = [:title, :description, :author_id, :project_id, :state].freeze
        REQUIREMENT_ISSUE_TYPE = 3
        INTERNAL_ID_ISSUES_USAGE = 0 # id for "issues" usage check Enums::InternalId.usage_resources

        class Requirement < ActiveRecord::Base; end
        class Issue < ActiveRecord::Base; end
        class WorkItemType < ActiveRecord::Base; end

        # This is almost a hard copy of app/models/internal_id.rb
        # with exception of some variables and functions that are not needed.
        #
        # Because we are generating iids manually we need to keep
        # track of latest issue iid for each project like we do in the app.
        # This avoids trying to create issues with already used iids and violating
        # unique indexes after this migration runs.
        class InternalId < ActiveRecord::Base
          class << self
            def generate_next(scope)
              build_generator(scope).generate
            end

            def build_generator(scope)
              ImplicitlyLockingInternalIdGenerator.new(scope)
            end
          end

          class ImplicitlyLockingInternalIdGenerator
            attr_reader :subject, :scope

            RecordAlreadyExists = Class.new(StandardError)

            def initialize(scope)
              @scope = scope
            end

            def generate
              next_iid = update_record!(scope, arel_table[:last_value] + 1)

              return next_iid if next_iid

              create_record!(scope, initial_value(scope) + 1)
            end

            def update_record!(scope, new_value)
              stmt = Arel::UpdateManager.new
              stmt.table(arel_table)
              stmt.set(arel_table[:last_value] => new_value)
              stmt.wheres = InternalId.where(**scope, usage: INTERNAL_ID_ISSUES_USAGE).arel.constraints

              InternalId.connection.insert(stmt, 'Update InternalId', 'last_value')
            end

            def create_record!(scope, value)
              attributes = {
                project_id: scope[:project_id],
                namespace_id: scope[:namespace_id],
                usage: INTERNAL_ID_ISSUES_USAGE,
                last_value: value
              }

              result = InternalId.insert(attributes)

              raise RecordAlreadyExists if result.empty?

              value
            end

            def initial_value(scope)
              # Same logic from AtomicInternalId.project_init
              Issue.where(project_id: scope[:project_id]).maximum(:iid) || 0
            end

            def arel_table
              InternalId.arel_table
            end
          end
        end

        override :perform
        def perform(start_id, end_id)
          requirements = Requirement.where(id: start_id..end_id, issue_id: nil)

          requirements.each do |requirement|
            Requirement.transaction do
              issue = create_issue_for(requirement)

              # Updates requirement with issue_id to keep future changes in sync
              requirement.update!(issue_id: issue.id)
            end
          end

          mark_job_as_succeeded(start_id, end_id)
        end

        private

        def create_issue_for(requirement)
          params = requirement.slice(*SYNC_PARAMS)
          next_iid = InternalId.generate_next({ project_id: requirement.project_id })

          Issue.create! do |issue|
            issue.iid = next_iid
            issue.title = params[:title]
            issue.description = params[:description]
            issue.state_id = params[:state]
            issue.author_id = params[:author_id]
            issue.project_id = params[:project_id]
            issue.issue_type = REQUIREMENT_ISSUE_TYPE
            issue.created_at = requirement.created_at
            issue.work_item_type_id = requirement_work_item_type_id
            issue.updated_at = Time.current
          end
        end

        def requirement_work_item_type_id
          @issue_work_item_type_id ||= WorkItemType.find_by(namespace_id: nil, name: 'Requirement').id
        end

        def mark_job_as_succeeded(*arguments)
          ::Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
            self.class.name.demodulize,
            arguments
          )
        end
      end
    end
  end
end
