# frozen_string_literal: true

module EE
  module Resolvers
    module WorkItemsResolver
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        argument :status_widget, ::Types::WorkItems::Widgets::StatusFilterInputType,
                 required: false,
                 description: 'Input for status widget filter.'
      end

      private

      override :widget_preloads
      def widget_preloads
        super.merge(status: { requirement: :recent_test_reports })
      end
    end
  end
end
