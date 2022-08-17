# frozen_string_literal: true

module ComplianceManagement
  class Framework < ApplicationRecord
    include StripAttribute

    self.table_name = 'compliance_management_frameworks'

    strip_attributes! :name, :color

    belongs_to :namespace
    has_many :project_settings, class_name: 'ComplianceManagement::ComplianceFramework::ProjectSettings'
    has_many :projects, through: :project_settings

    validates :namespace, presence: true
    validates :name, presence: true, length: { maximum: 255 }
    validates :description, presence: true, length: { maximum: 255 }
    validates :color, color: true, allow_blank: false, length: { maximum: 10 }
    validates :namespace_id, uniqueness: { scope: :name }
    validates :pipeline_configuration_full_path, length: { maximum: 255 }

    # Remove this validation once support for user namespaces is added.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/358423
    validate :namespace_is_root_level_group

    scope :with_projects, ->(project_ids) { includes(:projects).where(projects: { id: project_ids }) }
    scope :with_namespaces, ->(namespace_ids) { includes(:namespace).where(namespaces: { id: namespace_ids }) }

    private

    def namespace_is_root_level_group
      errors.add(:namespace, 'must be a group, user namespaces are not supported.') unless namespace.group_namespace?
      errors.add(:namespace, 'must be a root group.') if namespace.has_parent?
    end
  end
end
