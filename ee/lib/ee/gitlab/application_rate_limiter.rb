# frozen_string_literal: true

module EE
  module Gitlab
    module ApplicationRateLimiter
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :rate_limits
        def rate_limits
          super.merge({
            unique_project_downloads: {
              threshold: -> { application_settings.max_number_of_repository_downloads },
              interval:  -> { application_settings.max_number_of_repository_downloads_within_time_period }
            }
          }).freeze
        end
      end
    end
  end
end
