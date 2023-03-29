# frozen_string_literal: true

module WorkItems
  module Widgets
    module StatusService
      class UpdateService < WorkItems::Widgets::BaseService
        def before_update_in_transaction(params:)
          return remove_test_report_associations if new_type_excludes_widget?

          return unless has_permission?(:create_requirement_test_report)
          return unless params&.has_key?(:status)

          status_param = params[:status]

          test_report =
            RequirementsManagement::TestReport.build_report(
              requirement_issue: work_item,
              state: status_param,
              author: current_user
            )

          work_item.touch if test_report.save
        end

        private

        def remove_test_report_associations
          test_reports = work_item.test_reports
          return if test_reports.empty?

          work_item.requirement.destroy
          work_item.touch
        end
      end
    end
  end
end
