# frozen_string_literal: true
class ProtectedEnvironment::DeployAccessLevel < ApplicationRecord
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

  belongs_to :user
  belongs_to :group
  belongs_to :protected_environment, inverse_of: :deploy_access_levels

  validates :access_level, presence: true, inclusion: { in: ALLOWED_ACCESS_LEVELS }

  def check_access(user)
    return false unless user
    return true if user.admin?
    return user.id == user_id if user_type?
    return group.member?(user) if group_type?

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
