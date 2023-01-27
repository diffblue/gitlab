# frozen_string_literal: true

module EE
  module Resolvers
    module WorkItemsResolver
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        argument :status_widget, ::Types::WorkItems::Widgets::StatusFilterInputType,
                 required: false,
                 description: 'Input for status widget filter. Ignored if `work_items_mvc_2` is disabled.'
        argument :requirement_legacy_widget, ::Types::WorkItems::Widgets::RequirementLegacyFilterInputType,
                 required: false,
                 deprecated: { reason: 'Use work item IID filter instead', milestone: '15.9' },
                 description: 'Input for legacy requirement widget filter.'
      end

      override :resolve_with_lookahead
      def resolve_with_lookahead(**args)
        args.delete(:status_widget) unless resource_parent&.work_items_mvc_2_feature_flag_enabled?

        super
      end

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
