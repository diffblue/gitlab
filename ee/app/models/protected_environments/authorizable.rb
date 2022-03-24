# frozen_string_literal: true

module ProtectedEnvironments
  module Authorizable
    extend ActiveSupport::Concern

    included do
      belongs_to :user
      belongs_to :group
    end

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
      return group.users.exists?(user.id) if group_type?

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

    def humanize
      return user.name if user_type?
      return group.name if group_type?

      HUMAN_ACCESS_LEVELS[access_level]
    end
  end
end
