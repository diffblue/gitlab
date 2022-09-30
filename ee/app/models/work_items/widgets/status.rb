# frozen_string_literal: true

module WorkItems
  module Widgets
    class Status < Base
      # Adding this because test report 'passed' status should render a 'satisfied' badge
      # for verification status, which is aligned with the current implementation and the widget
      # requirements described at https://gitlab.com/gitlab-org/gitlab/-/issues/362155#verification-status-badge-display
      STATUS_MAP = {
        'passed' => 'satisfied',
        'failed' => 'failed'
      }.with_indifferent_access.freeze

      def status
        last_status = work_item.requirement&.last_test_report_state

        STATUS_MAP[last_status] || 'unverified'
      end
    end
  end
end
