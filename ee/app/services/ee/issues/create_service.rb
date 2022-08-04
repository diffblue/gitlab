# frozen_string_literal: true

module EE
  module Issues
    module CreateService
      extend ::Gitlab::Utils::Override

      override :create
      def create(issuable, skip_system_notes: false)
        process_iteration_id

        super
      end

      override :filter_params
      def filter_params(issue)
        filter_epic(issue)

        super
      end

      override :execute
      def execute(skip_system_notes: false)
        super.tap do |issue|
          if issue.previous_changes.include?(:milestone_id) && issue.epic_issue
            ::Epics::UpdateDatesService.new([issue.epic_issue.epic]).execute
          end
        end
      end

      override :transaction_create
      def transaction_create(issue)
        return super unless issue.requirement?

        requirement = issue.build_requirement(project: issue.project)
        requirement.requirement_issue = issue

        issue.requirement_sync_error! unless requirement.valid?

        super
      end
    end
  end
end
