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

      override :before_create
      def before_create(issue)
        super

        assign_requirement_to_be_synced_for(issue)
      end

      override :after_create
      def after_create(issue)
        super

        requirement_to_sync.issue_id = issue.id if requirement_to_sync

        save_requirement
      end
    end
  end
end
