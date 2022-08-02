# frozen_string_literal: true

module EE
  module Resolvers
    module WorkItemsResolver
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :filtered_preloads
      def filtered_preloads
        widgets = node_selection&.selection(:widgets)
        return [] unless widgets&.selected?

        verification_status = widgets.selection(
          :verification_status,
          selected_type: ::Types::WorkItems::Widgets::VerificationStatusType
        )

        return [] unless verification_status&.selected?

        # If verificationStatus field is present we need to preload test reports to prevent N+1 queries
        [{ requirement: :recent_test_reports }]
      end
    end
  end
end
