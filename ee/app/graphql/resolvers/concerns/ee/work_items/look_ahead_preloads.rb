# frozen_string_literal: true

module EE
  module WorkItems
    module LookAheadPreloads
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :widget_preloads
      def widget_preloads
        super.merge(
          status: { requirement: :recent_test_reports },
          progress: :progress,
          test_reports: :test_reports
        )
      end
    end
  end
end
