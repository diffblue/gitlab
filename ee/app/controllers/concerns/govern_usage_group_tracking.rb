# frozen_string_literal: true

module GovernUsageGroupTracking
  extend ActiveSupport::Concern

  included do
    include GovernUsageTracking
  end

  private

  def tracking_namespace_source
    group
  end

  def tracking_project_source
    nil
  end
end
