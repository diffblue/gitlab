# frozen_string_literal: true

module EE
  module API
    module Helpers
      module ResourceLabelEventsHelpers
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :feature_category_per_eventable_type
          def feature_category_per_eventable_type
            super.merge!(
              ::Epic => :portfolio_management
            )
          end
        end
      end
    end
  end
end
