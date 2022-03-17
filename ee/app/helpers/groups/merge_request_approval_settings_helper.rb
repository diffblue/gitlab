# frozen_string_literal: true

module Groups
  module MergeRequestApprovalSettingsHelper
    def show_merge_request_approval_settings?(user, group)
      user.can?(:admin_merge_request_approval_settings, group)
    end
  end
end
