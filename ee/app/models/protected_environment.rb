# frozen_string_literal: true
class ProtectedEnvironment < ApplicationRecord
  include ::Gitlab::Utils::StrongMemoize
  include FromUnion
  include EachBatch

  belongs_to :project
  belongs_to :group, inverse_of: :protected_environments
  has_many :deploy_access_levels, class_name: 'ProtectedEnvironments::DeployAccessLevel', inverse_of: :protected_environment
  has_many :approval_rules, class_name: 'ProtectedEnvironments::ApprovalRule', inverse_of: :protected_environment

  accepts_nested_attributes_for :deploy_access_levels, allow_destroy: true
  accepts_nested_attributes_for :approval_rules, allow_destroy: true

  validates :deploy_access_levels, length: { minimum: 1 }
  validates :name, presence: true
  validate :valid_tier_name, if: :group_level?
  validates :required_approval_count, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }

  scope :sorted_by_name, -> { order(:name) }

  scope :with_environment_id, -> do
    select('protected_environments.*, environments.id AS environment_id')
      .joins('LEFT OUTER JOIN environments ON' \
             ' protected_environments.name = environments.name ' \
             ' AND protected_environments.project_id = environments.project_id')
  end

  scope :for_groups, ->(group_ids) do
    where(group_id: group_ids).order(:name).preload(:deploy_access_levels)
  end

  class << self
    def names_for_projects(project_ids)
      where(project_id: project_ids).pluck(:name)
    end

    def tiers_for_groups(group_ids)
      where(group_id: group_ids).pluck(:name)
    end

    def revoke_user(user)
      transaction do
        ProtectedEnvironments::DeployAccessLevel
          .where(protected_environment_id: select(:id))
          .where(user: user)
          .delete_all

        ProtectedEnvironments::ApprovalRule
          .where(protected_environment_id: select(:id))
          .where(user: user)
          .delete_all
      end
    end

    def revoke_group(group)
      transaction do
        ProtectedEnvironments::DeployAccessLevel
          .where(protected_environment_id: select(:id))
          .where(group: group)
          .delete_all

        ProtectedEnvironments::ApprovalRule
          .where(protected_environment_id: select(:id))
          .where(group: group)
          .delete_all
      end
    end

    def for_environment(environment)
      raise ArgumentError unless environment.is_a?(::Environment)

      key = "protected_environment:for_environment:#{environment.id}"

      ::Gitlab::SafeRequestStore.fetch(key) { for_environments([environment]) }
    end

    def for_environments(environments)
      raise ArgumentError, 'Environments must be in the same project' if environments.map(&:project_id).uniq.size > 1

      project_id = environments.first.project_id
      group_ids = environments.first.project.ancestors_upto_ids
      names = environments.map(&:name)
      tiers = environments.map(&:tier)

      from_union([
                   where(project: project_id, name: names),
                   where(group: group_ids, name: tiers)
                 ])
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

  def project_level?
    project_id.present?
  end

  def group_level?
    group_id.present?
  end

  private

  def valid_tier_name
    unless Environment.tiers[name]
      errors.add(:name, "must be one of environment tiers: #{Environment.tiers.keys.join(', ')}.")
    end
  end
end
