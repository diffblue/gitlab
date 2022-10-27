# frozen_string_literal: true

module WorkItems
  module Widgets
    module Filters
      class Status
        def self.filter(relation, params)
          status = params.dig(:status_widget, :status)

          return relation unless status

          relation = relation.with_issue_type(:requirement)

          if status == 'missing'
            relation.without_test_reports
          else
            relation.with_last_test_report_state(status)
          end
        end
      end
    end
  end
end
