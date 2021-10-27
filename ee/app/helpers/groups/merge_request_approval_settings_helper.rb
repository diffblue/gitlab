# frozen_string_literal: true

module Groups
  module MergeRequestApprovalSettingsHelper
    def show_merge_request_approval_settings?(user, group)
      Feature.enabled?(:group_merge_request_approval_settings_feature_flag, group, default_enabled: :yaml) &&
        user.can?(:admin_merge_request_approval_settings, group)
    end
  end
end
