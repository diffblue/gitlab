# frozen_string_literal: true

module ProductAnalytics
  class Visualization
    attr_reader :type, :project, :data, :options, :config, :slug, :errors

    VISUALIZATIONS_ROOT_LOCATION = '.gitlab/analytics/dashboards/visualizations'
    SCHEMA_PATH = 'ee/app/validators/json_schemas/analytics_visualization.json'

    PRODUCT_ANALYTICS_PATH = 'ee/lib/gitlab/analytics/product_analytics/visualizations'
    PRODUCT_ANALYTICS_VISUALIZATIONS = %w[
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
    ].freeze

    VALUE_STREAM_DASHBOARD_PATH = 'ee/lib/gitlab/analytics/value_stream_dashboard/visualizations'
    VALUE_STREAM_DASHBOARD_VISUALIZATIONS = %w[dora_chart].freeze

    def self.for_project(project)
      config_project = project.analytics_dashboards_configuration_project || project

      trees = config_project.repository.tree(:head, VISUALIZATIONS_ROOT_LOCATION)

      trees.entries.map do |entry|
        config = config_project.repository.blob_data_at(config_project.repository.root_ref_sha, entry.path)

        new(config: config, slug: File.basename(entry.name, File.extname(entry.name)))
      end.append(*builtin_visualizations(project))
    end

    def self.load_visualization_data(path, data)
      file = Rails.root.join(path, "#{data}.yaml")
      Gitlab::PathTraversal.check_path_traversal!(data)
      Gitlab::PathTraversal.check_allowed_absolute_path!(
        file.to_s, [Rails.root.join(path).to_s]
      )
      new(config: File.read(file), slug: data)
    end

    def self.load_product_analytics_visualization(data)
      load_visualization_data(PRODUCT_ANALYTICS_PATH, data)
    end

    def self.load_value_stream_dashboard_visualization(data)
      load_visualization_data(VALUE_STREAM_DASHBOARD_PATH, data)
    end

    def self.from_data(data:, project:)
      config = project.repository.blob_data_at(
        project.repository.root_ref_sha,
        visualization_config_path(data)
      )

      return new(config: config, slug: data) if config

      if VALUE_STREAM_DASHBOARD_VISUALIZATIONS.include?(data)
        load_value_stream_dashboard_visualization(data)
      else
        load_product_analytics_visualization(data)
      end
    end

    def initialize(config:, slug:)
      begin
        @config = YAML.safe_load(config)
        @type = @config['type']
        @options = @config['options']
        @data = @config['data']
      rescue Psych::Exception => e
        @errors = [e.message]
      end
      @slug = slug.parameterize.underscore
      validate
    end

    def validate
      validator = JSONSchemer.schema(Pathname.new(SCHEMA_PATH))
      validator_errors = validator.validate(@config)
      @errors = validator_errors.map { |e| JSONSchemer::Errors.pretty(e) } if validator_errors.any?
    end

    def self.visualization_config_path(data)
      "#{ProductAnalytics::Dashboard::DASHBOARD_ROOT_LOCATION}/visualizations/#{data}.yaml"
    end

    def self.load_visualizations(visualization_names, directory)
      visualization_names.map do |name|
        config = File.read(Rails.root.join(directory, "#{name}.yaml"))

        new(config: config, slug: name)
      end
    end

    def self.product_analytics_visualizations
      load_visualizations(PRODUCT_ANALYTICS_VISUALIZATIONS, PRODUCT_ANALYTICS_PATH)
    end

    def self.value_stream_dashboard_visualizations
      load_visualizations(VALUE_STREAM_DASHBOARD_VISUALIZATIONS, VALUE_STREAM_DASHBOARD_PATH)
    end

    def self.value_stream_dashboards_available?(project)
      project.licensed_feature_available?(:project_level_analytics_dashboard)
    end

    def self.builtin_visualizations(project)
      visualizations = []

      visualizations << product_analytics_visualizations

      visualizations << value_stream_dashboard_visualizations if value_stream_dashboards_available?(project)

      visualizations.flatten
    end
  end
end
