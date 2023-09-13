# frozen_string_literal: true

module EE
  module Boards
    module UpdateService
      extend ::Gitlab::Utils::Override

      override :filter_params
      def filter_params
        super

        filter_assignee
        filter_labels
        filter_milestone
        filter_iteration_and_iteration_cadence
      end

      override :permitted_params
      def permitted_params
        permitted = super

        if parent.feature_available?(:scoped_issue_board)
          permitted += %i[milestone_id iteration_id iteration_cadence_id assignee_id weight labels label_ids]
        end

        permitted
      end
    end
  end
end
