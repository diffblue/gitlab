# frozen_string_literal: true

module WorkItems
  module Widgets
    module StatusService
      class UpdateService < WorkItems::Widgets::BaseService
        def before_update_in_transaction(params:)
          return unless params&.has_key?(:status)
          return unless has_permission?(:create_requirement_test_report)

          status_param = params[:status]

          test_report =
            RequirementsManagement::TestReport.build_report(
              requirement_issue: work_item,
              state: status_param,
              author: current_user
            )

          work_item.touch if test_report.save
        end
      end
    end
  end
end
