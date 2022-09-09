# frozen_string_literal: true

module EE
  module API
    module Helpers
      module ResourceEventsHelpers
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :eventable_types
          def eventable_types
            super.merge!(
              ::Epic => { feature_category: :portfolio_management, id_field: 'ID' }
            )
          end
        end
      end
    end
  end
end
