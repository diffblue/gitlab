# frozen_string_literal: true

module Projects
  module ComplianceStandards
    class Adherence < ApplicationRecord
      self.table_name = 'project_compliance_standards_adherence'

      enum status: ::Enums::Projects::ComplianceStandards::Adherence.status
      enum check_name: ::Enums::Projects::ComplianceStandards::Adherence.check_name
      enum standard: ::Enums::Projects::ComplianceStandards::Adherence.standard

      belongs_to :project
      belongs_to :namespace

      validates_presence_of :project, :namespace, :check_name, :standard, :status
      validates :project, uniqueness: { scope: [:check_name, :standard],
                                        message: "already has this check defined for this standard" }
      validate :namespace_is_group

      scope :for_group, ->(group) { where(namespace: group) }
      scope :for_group_and_its_subgroups, ->(group) { where(namespace: group.self_and_descendants_ids) }
      scope :for_projects, ->(project_ids) { where(project: project_ids) }
      scope :for_check_name, ->(check_name) { where(check_name: check_name) }
      scope :for_standard, ->(standard) { where(standard: standard) }

      private

      def namespace_is_group
        return if project&.namespace&.group_namespace?

        errors.add(:namespace_id, 'must be a group, user namespaces are not supported.')
      end
    end
  end
end
