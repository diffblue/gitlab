# frozen_string_literal: true

module ProtectedEnvironments
  module Authorizable
    extend ActiveSupport::Concern

    included do
      belongs_to :user
      belongs_to :group
    end

    GROUP_INHERITANCE_TYPE = {
      DIRECT: 0,
      ALL: 1
    }.freeze

    ALLOWED_ACCESS_LEVELS = [
      Gitlab::Access::MAINTAINER,
      Gitlab::Access::DEVELOPER,
      Gitlab::Access::REPORTER,
      Gitlab::Access::ADMIN
    ].freeze

    HUMAN_ACCESS_LEVELS = {
      Gitlab::Access::MAINTAINER => 'Maintainers',
      Gitlab::Access::DEVELOPER => 'Developers + Maintainers'
    }.freeze

    def check_access(user)
      return false unless user
      return true if user.admin? # rubocop: disable Cop/UserAdmin
      return user.id == user_id if user_type?

      if inherit_group_membership?
        return group.member?(user) if group_type?
      elsif group_type?
        return group.users.exists?(user.id)
      end

      protected_environment.container_access_level(user) >= access_level
    end

    def user_type?
      user_id.present?
    end

    def group_type?
      group_id.present?
    end

    def type
      if user_type?
        :user
      elsif group_type?
        :group
      else
        :role
      end
    end

    def role?
      type == :role
    end

    def inherit_group_membership?
      group_inheritance_type == GROUP_INHERITANCE_TYPE[:ALL]
    end

    def humanize
      return user.name if user_type?
      return group.name if group_type?

      HUMAN_ACCESS_LEVELS[access_level]
    end
  end
end
