# frozen_string_literal: true

module EE::Groups::Analytics::CycleAnalyticsHelper
  include Analytics::CycleAnalyticsHelper

  def group_cycle_analytics_data(group)
    api_paths = group.present? ? cycle_analytics_api_paths(group) : {}
    image_paths = cycle_analytics_image_paths
    default_stages = { default_stages: cycle_analytics_default_stage_config.to_json }

    api_paths.merge(image_paths, default_stages)
  end

  private

  def cycle_analytics_image_paths
    {
      empty_state_svg_path: image_path("illustrations/analytics/cycle-analytics-empty-chart.svg"),
      no_data_svg_path: image_path("illustrations/analytics/cycle-analytics-empty-chart.svg"),
      no_access_svg_path: image_path("illustrations/analytics/no-access.svg")
    }
  end

  def cycle_analytics_api_paths(group)
    { milestones_path: group_milestones_path(group, format: :json), labels_path: group_labels_path(group, format: :json) }
  end
end
