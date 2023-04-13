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

      data = ::Analytics::DoraMetricsAggregator.aggregate_for(
        projects: target_projects,
        metrics: metrics,
        interval: interval,
        start_date: start_date,
        end_date: end_date,
        environment_tiers: environment_tiers)

      post_process_deployment_frequency!(data)

      success(data: data)
    end

    private

    # The deployment frequency DB query returns the number of deployments which is not
    # the actual deployment frequency. To get the deployment frequency, we post-process
    # the data and calculate the average deployments within the time range.
    def post_process_deployment_frequency!(data)
      df_metric_name = Dora::DeploymentFrequencyMetric::METRIC_NAME

      if Feature.enabled?(:fix_dora_deployment_frequency_calculation, container)
        return unless metrics.include?(df_metric_name)

        interval_day_counts = case interval
                              when Dora::DailyMetrics::INTERVAL_ALL
                                # number of days between a date range (inclusive)
                                { nil => (end_date - start_date).to_i + 1 }
                              when Dora::DailyMetrics::INTERVAL_MONTHLY
                                # Calculating the number of days monthly by iterating over the days
                                # since date ranges can be arbitrary, for example:
                                # 2022-01-15 - 2022-02-28
                                #
                                # - For January, 2022-01-01: 17 days
                                # - For February, 2022-02-01: 28 days
                                (start_date..end_date).each_with_object({}) do |date, hash|
                                  beginning_of_month = date.beginning_of_month.to_s
                                  hash[beginning_of_month] ||= 0
                                  hash[beginning_of_month] += 1
                                end
                              end

        data.each do |row|
          next if interval_day_counts.nil?
          next if row[df_metric_name].nil?

          row['deployment_count'] = row[df_metric_name]
          row[df_metric_name] = row[df_metric_name].fdiv(interval_day_counts[row['date']])
        end
      else
        # make sure deployment_count is populated
        data.each do |row|
          row['deployment_count'] = row[df_metric_name] if row[df_metric_name]
        end
      end
    end

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
      params[:metrics] || []
    end

    def group_project_ids
      Array(params[:group_project_ids])
    end
  end
end
