# frozen_string_literal: true

class MemberRole < ApplicationRecord # rubocop:disable Gitlab/NamespacedClass
  MAX_COUNT_PER_GROUP_HIERARCHY = 10
  ALL_CUSTOMIZABLE_PERMISSIONS = {
    read_code:
      { description: 'Permission to read code', minimal_level: Gitlab::Access::GUEST },
    read_dependency: {
      description: 'Permission to read dependency',
      minimal_level: Gitlab::Access::GUEST
    },
    read_vulnerability:
      { descripition: 'Permission to read vulnerability', minimal_level: Gitlab::Access::GUEST },
    admin_vulnerability: {
      descripition: 'Permission to admin vulnerability',
      minimal_level: Gitlab::Access::GUEST,
      requirement: :read_vulnerability
    }
  }.freeze
  CUSTOMIZABLE_PERMISSIONS_EXEMPT_FROM_CONSUMING_SEAT = [:read_code].freeze
  NON_PERMISSION_COLUMNS = [:id, :namespace_id, :created_at, :updated_at, :base_access_level].freeze

  has_many :members
  belongs_to :namespace

  validates :namespace, presence: true
  validates :base_access_level, presence: true
  validate :belongs_to_top_level_namespace
  validate :max_count_per_group_hierarchy, on: :create
  validate :validate_namespace_locked, on: :update
  validate :attributes_locked_after_member_associated, on: :update
  validate :validate_minimal_base_access_level
  validate :validate_requirements

  validates_associated :members

  scope :elevating, -> do
    return none unless Feature.enabled?(:elevated_guests)
    return none if elevating_permissions.empty?

    query = elevating_permissions.map { |permission| "#{permission} = true" }
                                 .join(" OR ")
    where(query)
  end

  before_destroy :prevent_delete_after_member_associated
  class << self
    def elevating_permissions
      ALL_CUSTOMIZABLE_PERMISSIONS.keys - CUSTOMIZABLE_PERMISSIONS_EXEMPT_FROM_CONSUMING_SEAT
    end
  end

  private

  def belongs_to_top_level_namespace
    return if !namespace || namespace.root?

    errors.add(:namespace, s_("MemberRole|must be top-level namespace"))
  end

  def max_count_per_group_hierarchy
    return unless namespace
    return if namespace.member_roles.count < MAX_COUNT_PER_GROUP_HIERARCHY

    errors.add(
      :namespace,
      s_(
        "MemberRole|maximum number of Member Roles are already in use by the group hierarchy. " \
        "Please delete an existing Member Role."
      )
    )
  end

  def validate_namespace_locked
    return unless namespace_id_changed?

    errors.add(:namespace, s_("MemberRole|can't be changed"))
  end

  def validate_minimal_base_access_level
    ALL_CUSTOMIZABLE_PERMISSIONS.each do |permission, params|
      min_level = params[:minimal_level]
      next unless self[permission]
      next if base_access_level >= min_level

      errors.add(:base_access_level,
        format(s_("MemberRole|minimal base access level must be %{min_access_level}."),
          min_access_level: "#{Gitlab::Access.options_with_owner.key(min_level)} (#{min_level})")
      )
    end
  end

  def validate_requirements
    ALL_CUSTOMIZABLE_PERMISSIONS.each do |permission, params|
      requirement = params[:requirement]

      next unless self[permission] # skipping permissions not set for the object
      next unless requirement # skipping permissions that have no requirement
      next if self[requirement] # the requierement is met

      errors.add(permission,
        format(s_("MemberRole|%{requirement} has to be enabled in order to enable %{permission}."),
          requirement: requirement, permission: permission)
      )
    end
  end

  def attributes_locked_after_member_associated
    return unless members.present?

    errors.add(
      :base,
      s_(
        "MemberRole|cannot be changed because it is already assigned to a user. " \
        "Please create a new Member Role instead"
      )
    )
  end

  def prevent_delete_after_member_associated
    return unless members.present?

    errors.add(
      :base,
      s_(
        "MemberRole|cannot be deleted because it is already assigned to a user. " \
        "Please disassociate the member role from all users before deletion."
      )
    )

    throw :abort # rubocop:disable Cop/BanCatchThrow
  end
end
