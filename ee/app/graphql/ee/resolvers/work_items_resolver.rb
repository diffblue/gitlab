# frozen_string_literal: true

module EE
  module Resolvers
    module WorkItemsResolver
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :widget_preloads
      def widget_preloads
        super.merge(verification_status: { requirement: :recent_test_reports })
      end
    end
  end
end
