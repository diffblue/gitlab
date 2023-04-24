# frozen_string_literal: true

# EE-specific code related to protected branch/tag access levels.
#
# Note: Don't directly include this concern into a model class.
# Instead, include `ProtectedBranchAccess` or `ProtectedTagAccess`, which in
# turn include this concern. A number of methods here depend on
# `ProtectedRefAccess` being next up in the ancestor chain.

module EE
  module ProtectedRefAccess
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    module Scopes
      extend ActiveSupport::Concern

      included do
        belongs_to :user
        belongs_to :group

        protected_type = module_parent.model_name.singular
        validates :group_id, uniqueness: { scope: protected_type, allow_nil: true }
        validates :user_id, uniqueness: { scope: protected_type, allow_nil: true }
        validates :access_level, uniqueness: { scope: protected_type, if: :role?,
                                               conditions: -> { where(user_id: nil, group_id: nil) } }
        validates :group, :user, absence: true,
          unless: -> { importing? || protected_refs_for_users_required_and_available }

        validate :validate_group_membership, if: -> { !importing? && protected_refs_for_users_required_and_available }
        validate :validate_user_membership, if: -> { !importing? && protected_refs_for_users_required_and_available }
      end
    end

    class_methods do
      # We can't specify `override` here:
      #   https://gitlab.com/gitlab-org/gitlab-foss/issues/50911
      def allowed_access_levels
        [
          *super,
          ::Gitlab::Access::ADMIN
        ]
      end
    end

    override :type
    def type
      return :user if user.present?
      return :group if group.present?

      super
    end

    override :humanize
    def humanize
      return user.name if user.present?
      return group.name if group.present?

      super
    end

    override :check_access
    def check_access(user)
      return false unless user
      return true if user.admin?
      return user.id == self.user_id if self.user.present?
      return group.users.exists?(user.id) if self.group.present?

      super
    end

    # We don't need to validate the license if this access applies to a role.
    #
    # If it applies to a user/group we can only skip validation `nil`-validation
    # if the feature is available
    def protected_refs_for_users_required_and_available
      type != :role && project.feature_available?(:protected_refs_for_users)
    end

    def validate_group_membership
      return unless group

      unless project.project_group_links.where(group: group).exists?
        errors.add(:group, 'does not have access to the project')
      end
    end

    def validate_user_membership
      return unless user

      unless project.team.member?(user)
        errors.add(:user, 'is not a member of the project')
      end
    end
  end
end
