# frozen_string_literal: true

module ProductAnalytics
  class Visualization
    attr_reader :type, :project, :data, :options, :config, :slug

    VISUALIZATIONS_ROOT_LOCATION = '.gitlab/analytics/dashboards/visualizations'

    def self.for_project(project)
      config_project = project.analytics_dashboards_configuration_project || project

      trees = config_project.repository.tree(:head, VISUALIZATIONS_ROOT_LOCATION)

      trees.entries.map do |entry|
        config = config_project.repository.blob_data_at(config_project.repository.root_ref_sha, entry.path)

        new(config: config, slug: File.basename(entry.name, File.extname(entry.name)))
      end.append(*builtin_visualizations)
    end

    def self.from_data(data:, project:)
      config = project.repository.blob_data_at(
        project.repository.root_ref_sha,
        visualization_config_path(data)
      )

      return new(config: config, slug: data) if config

      file = Rails.root.join('ee/lib/gitlab/analytics/product_analytics/visualizations', "#{data}.yaml")
      Gitlab::PathTraversal.check_path_traversal!(data)
      Gitlab::PathTraversal.check_allowed_absolute_path!(
        file.to_s, [Rails.root.join('ee/lib/gitlab/analytics/product_analytics/visualizations').to_s]
      )
      new(config: File.read(file), slug: data)
    end

    def initialize(config:, slug:)
      @config = YAML.safe_load(config)
      @type = @config['type']
      @options = @config['options']
      @data = @config['data']
      @slug = slug.parameterize.underscore
    end

    def self.visualization_config_path(data)
      "#{ProductAnalytics::Dashboard::DASHBOARD_ROOT_LOCATION}/visualizations/#{data}.yaml"
    end

    def self.builtin_visualizations
      visualization_names = %w[
        average_session_duration
        average_sessions_per_user
        browsers_per_users
        daily_active_users
        events_over_time
        page_views_over_time
        returning_users_percentage
        sessions_over_time
        sessions_per_browser
        top_pages
        total_events
        total_pageviews
        total_sessions
        total_unique_users
      ]
      visualization_names.map do |name|
        config = File.read(Rails.root.join('ee/lib/gitlab/analytics/product_analytics/visualizations', "#{name}.yaml"))

        new(config: config, slug: name)
      end
    end
  end
end
