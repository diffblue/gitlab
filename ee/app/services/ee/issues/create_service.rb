# frozen_string_literal: true

module EE
  module Issues
    module CreateService
      extend ::Gitlab::Utils::Override

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
    end
  end
end
