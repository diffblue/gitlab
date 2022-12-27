# frozen_string_literal: true

module EE
  module BasePolicy
    extend ActiveSupport::Concern

    prepended do
      with_scope :user
      condition(:auditor, score: 0) { @user&.auditor? }

      with_scope :user
      condition(:visual_review_bot, score: 0) { @user&.visual_review_bot? }

      desc "User is suggested reviewers bot"
      with_scope :user
      condition(:suggested_reviewers_bot, score: 0) { @user&.suggested_reviewers_bot? }

      with_scope :global
      condition(:license_block) { License.block_changes? }

      rule { auditor }.enable :read_all_resources

      with_scope :global
      condition(:allow_to_manage_default_branch_protection) do
        # When un-licensed: Always allow access.
        # When licensed: Allow or deny access based on the
        # `group_owners_can_manage_default_branch_protection` setting.
        !License.feature_available?(:default_branch_protection_restriction_in_groups) ||
          ::Gitlab::CurrentSettings.group_owners_can_manage_default_branch_protection
      end
    end
  end
end
