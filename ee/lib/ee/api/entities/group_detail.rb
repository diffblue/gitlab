# frozen_string_literal: true

module EE
  module API
    module Entities
      module GroupDetail
        extend ActiveSupport::Concern

        prepended do
          include ::Admin::IpRestrictionHelper

          expose :shared_runners_minutes_limit
          expose :extra_shared_runners_minutes_limit
          expose :prevent_forking_outside_group?, as: :prevent_forking_outside_group
          expose :membership_lock?, as: :membership_lock
          expose :ip_restriction_ranges, if: ->(group, options) { ip_restriction_feature_available?(group) }

          unique_project_download_limit_enabled = lambda do |group, options|
            options[:current_user]&.can?(:admin_group, group) &&
              group.namespace_settings.present? &&
              group.unique_project_download_limit_enabled?
          end
          expose :unique_project_download_limit, if: unique_project_download_limit_enabled
          expose :unique_project_download_limit_interval_in_seconds, if: unique_project_download_limit_enabled
          expose :unique_project_download_limit_allowlist, if: unique_project_download_limit_enabled
          expose :unique_project_download_limit_alertlist, if: unique_project_download_limit_enabled
          expose :auto_ban_user_on_excessive_projects_download, if: unique_project_download_limit_enabled

          private

          def unique_project_download_limit
            settings&.unique_project_download_limit
          end

          def unique_project_download_limit_interval_in_seconds
            settings&.unique_project_download_limit_interval_in_seconds
          end

          def unique_project_download_limit_allowlist
            settings&.unique_project_download_limit_allowlist
          end

          def unique_project_download_limit_alertlist
            settings&.unique_project_download_limit_alertlist
          end

          def auto_ban_user_on_excessive_projects_download
            settings&.auto_ban_user_on_excessive_projects_download
          end

          def settings
            object&.namespace_settings
          end
        end
      end
    end
  end
end
