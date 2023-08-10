# frozen_string_literal: true

module GovernUsageProjectTracking
  extend ActiveSupport::Concern

  included do
    include GovernUsageTracking
  end

  private

  def tracking_namespace_source
    project.namespace
  end

  def tracking_project_source
    project
  end
end
