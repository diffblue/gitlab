# frozen_string_literal: true

module EE::Projects::Analytics::CycleAnalytics::SummaryController
  extend ActiveSupport::Concern
  extend ::Gitlab::Utils::Override

  def time_summary
    if project.licensed_feature_available?(:cycle_analytics_for_projects)
      render json: project_level.time_summary
    else
      render_404
    end
  end
end
