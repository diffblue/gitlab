# frozen_string_literal: true

module EE
  module API
    module Helpers
      module DiscussionsHelpers
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :feature_category_per_noteable_type
          def feature_category_per_noteable_type
            super.merge!(::Epic => :team_planning)
          end
        end
      end
    end
  end
end
