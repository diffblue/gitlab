# frozen_string_literal: true

module Dora
  class AggregateMetricsService < ::BaseContainerService
    MAX_RANGE = Gitlab::Analytics::CycleAnalytics::RequestParams::MAX_RANGE_DAYS # same range as Value Stream Analytics

    DEFAULT_ENVIRONMENT_TIERS = %w[production].freeze
    DEFAULT_INTERVAL = Dora::DailyMetrics::INTERVAL_DAILY

    def execute
      if error = validate_container
        return error
      end

      return authorization_error unless authorized?

      execute_without_authorization
    end

    def execute_without_authorization
      if error = validate_container
        return error
      end

      if error = validate
        return error
      end

      data = ::Dora::DailyMetrics
        .for_environments(environments)
        .in_range_of(start_date, end_date)
        .aggregate_for!(metrics, interval)

      data = backwards_compatibility_convert(data)

      success(data: data)
    end

    private

    def authorized?
      return false unless project_container? || group_container?

      can?(current_user, :read_dora4_analytics, container)
    end

    def authorization_error
      error(_('You do not have permission to access dora metrics.'), :unauthorized)
    end

    def validate_container
      unless project_container? || group_container?
        error(_('Container must be a project or a group.'), :bad_request)
      end
    end

    def validate
      unless (end_date - start_date).days <= MAX_RANGE
        return error(_("Date range must be shorter than %{max_range} days.") % { max_range: MAX_RANGE.in_days.to_i },
                     :bad_request)
      end

      unless start_date < end_date
        return error(_('The start date must be earlier than the end date.'), :bad_request)
      end

      if group_project_ids.present? && !group_container?
        return error(_('The group_project_ids parameter is only allowed for a group'), :bad_request)
      end

      unless ::Dora::DailyMetrics::AVAILABLE_INTERVALS.include?(interval)
        return error(_("The interval must be one of %{intervals}.") % { intervals: ::Dora::DailyMetrics::AVAILABLE_INTERVALS.join(',') },
                     :bad_request)
      end

      if metrics.empty?
        return error(_("The metric must be one of %{metrics}.") % { metrics: ::Dora::DailyMetrics::AVAILABLE_METRICS.join(',') },
                     :bad_request)
      end

      metrics.each do |metric|
        unless ::Dora::DailyMetrics::AVAILABLE_METRICS.include?(metric)
          return error(_("The metric must be one of %{metrics}.") % { metrics: ::Dora::DailyMetrics::AVAILABLE_METRICS.join(',') },
                       :bad_request)
        end
      end

      unless environment_tiers.all? { |tier| Environment.tiers[tier] }
        return error(_("The environment tiers must be from %{environment_tiers}.") % { environment_tiers: Environment.tiers.keys.join(', ') },
                     :bad_request)
      end

      nil
    end

    def environments
      Environment.for_project(target_projects).for_tier(environment_tiers)
    end

    def target_projects
      if project_container?
        [container]
      elsif group_container?
        # The actor definitely has read permission in all subsequent projects of the group by the following reasons:
        # - DORA metrics can be read by reporter (or above) at project-level.
        # - With `read_dora4_analytics` permission check, we make sure that the
        #   user is at-least reporter role at group-level.
        # - In the subsequent projects, the assigned role at the group-level
        #   can't be lowered. For example, if the user is reporter at group-level,
        #   the user can be developer in subsequent projects, but can't be guest.
        projects = container.all_projects
        projects = projects.id_in(group_project_ids) if group_project_ids.any?
        projects
      end
    end

    def start_date
      params[:start_date] || 3.months.ago.to_date
    end

    def end_date
      params[:end_date] || Time.current.to_date
    end

    def environment_tiers
      params[:environment_tiers] || DEFAULT_ENVIRONMENT_TIERS
    end

    def interval
      params[:interval] || DEFAULT_INTERVAL
    end

    def metrics
      Array(params[:metric])
    end

    def group_project_ids
      Array(params[:group_project_ids])
    end

    def backwards_compatibility_convert(new_data)
      metric = metrics.first

      return new_data[metric] if interval == ::Dora::DailyMetrics::INTERVAL_ALL

      new_data.map { |row| { 'date' => row['date'], 'value' => row[metric] } }
    end
  end
end
