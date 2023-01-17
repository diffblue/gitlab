# frozen_string_literal: true

module Analytics
  class DashboardsPointer < ApplicationRecord
    self.table_name = 'analytics_dashboards_pointers'

    belongs_to :namespace
    belongs_to :project
    belongs_to :target_project, optional: false, class_name: 'Project'

    validate :check_namespace_or_project_presence

    validates :namespace_id, uniqueness: { scope: :project_id }, if: :namespace_id?
    validates :project_id, uniqueness: { scope: :namespace_id }, if: :project_id?

    private

    def check_namespace_or_project_presence
      if !namespace_id && !project_id
        errors.add(:base, _('Namespace or project is required'))
      elsif namespace_id && project_id
        errors.add(:base, _('Only one source is required but both were provided'))
      end
    end
  end
end
