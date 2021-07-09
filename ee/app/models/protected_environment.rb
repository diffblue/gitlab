# frozen_string_literal: true
class ProtectedEnvironment < ApplicationRecord
  include ::Gitlab::Utils::StrongMemoize
  include FromUnion

  belongs_to :project
  belongs_to :group, inverse_of: :protected_environments
  has_many :deploy_access_levels, inverse_of: :protected_environment

  accepts_nested_attributes_for :deploy_access_levels, allow_destroy: true

  validates :deploy_access_levels, length: { minimum: 1 }
  validates :name, presence: true
  validate :valid_tier_name, if: :group_level?

  scope :sorted_by_name, -> { order(:name) }

  scope :with_environment_id, -> do
    select('protected_environments.*, environments.id AS environment_id')
      .joins('LEFT OUTER JOIN environments ON' \
             ' protected_environments.name = environments.name ' \
             ' AND protected_environments.project_id = environments.project_id')
  end

  class << self
    def deploy_access_levels_by_user(user)
      ProtectedEnvironment::DeployAccessLevel
        .where(protected_environment_id: select(:id))
        .where(user: user)
    end

    def deploy_access_levels_by_group(group)
      ProtectedEnvironment::DeployAccessLevel
        .where(protected_environment_id: select(:id))
        .where(group: group)
    end

    def for_environment(environment)
      raise ArgumentError unless environment.is_a?(::Environment)

      key = "protected_environment:for_environment:#{environment.id}"

      ::Gitlab::SafeRequestStore.fetch(key) do
        from_union([
          where(project: environment.project_id, name: environment.name),
          where(group: environment.project.ancestors_upto_ids, name: environment.tier)
        ])
      end
    end
  end

  def accessible_to?(user)
    deploy_access_levels
      .any? { |deploy_access_level| deploy_access_level.check_access(user) }
  end

  def container_access_level(user)
    if project_level?
      project.team.max_member_access(user&.id)
    elsif group_level?
      group.max_member_access_for_user(user)
    end
  end

  private

  def valid_tier_name
    unless Environment.tiers[name]
      errors.add(:name, "must be one of environment tiers: #{Environment.tiers.keys.join(', ')}.")
    end
  end

  def project_level?
    project_id.present?
  end

  def group_level?
    group_id.present?
  end
end
