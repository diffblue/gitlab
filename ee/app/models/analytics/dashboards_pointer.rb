# frozen_string_literal: true

module Analytics
  class DashboardsPointer < ApplicationRecord
    self.table_name = 'analytics_dashboards_pointers'

    belongs_to :namespace, optional: false
    belongs_to :project, optional: false

    validates :namespace_id, uniqueness: true
  end
end
