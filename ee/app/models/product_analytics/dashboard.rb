# frozen_string_literal: true

module ProductAnalytics
  class Dashboard
    attr_reader :title, :description, :schema_version, :panels, :container,
      :config_project, :slug, :path, :user_defined, :category

    DASHBOARD_ROOT_LOCATION = '.gitlab/analytics/dashboards'

    PRODUCT_ANALYTICS_DASHBOARDS_LIST = %w[audience behavior].freeze
    VALUE_STREAM_DASHBOARD_LIST = %w[value_stream_dashboard].freeze

    def self.for(container:)
      unless container.is_a?(Group) || container.is_a?(Project)
        raise ArgumentError,
          "A group or project must be provided. Given object is #{container.class.name} type"
      end

      config_project =
        container.analytics_dashboards_configuration_project ||
        container.default_dashboards_configuration_source

      dashboards = []

      root_trees = config_project&.repository&.tree(:head, DASHBOARD_ROOT_LOCATION)

      dashboards << builtin_dashboards(container, config_project)
      dashboards << local_dashboards(container, config_project, root_trees.trees) if root_trees&.trees

      dashboards.flatten
    end

    def initialize(
      title:, description:, schema_version:, panels:, container:, slug:, user_defined:,
      config_project:)
      @title = title
      @description = description
      @schema_version = schema_version
      @panels = panels
      @container = container
      @config_project = config_project
      @slug = slug
      @user_defined = user_defined
      @category = 'analytics'
    end

    def self.local_dashboards(container, config_project, trees)
      trees.delete_if { |tree| tree.name == 'visualizations' }.map do |tree|
        config_data =
          config_project.repository.blob_data_at(config_project.repository.root_ref_sha,
            "#{tree.path}/#{tree.name}.yaml")

        next unless config_data

        config = YAML.safe_load(config_data)

        new(
          container: container,
          title: config['title'],
          slug: tree.name,
          description: config['description'],
          schema_version: config['version'],
          panels: ProductAnalytics::Panel.from_data(config['panels'], config_project),
          user_defined: true,
          config_project: config_project
        )
      end
    end

    def self.load_yaml_dashboard_config(name, file_path)
      Gitlab::PathTraversal.check_path_traversal!(name)

      YAML.safe_load(
        File.read(Rails.root.join(file_path, "#{name}.yaml"))
      )
    end

    def self.product_analytics_dashboards(container, config_project)
      return [] unless container.product_analytics_enabled?

      PRODUCT_ANALYTICS_DASHBOARDS_LIST.map do |name|
        config = load_yaml_dashboard_config(name, 'ee/lib/gitlab/analytics/product_analytics/dashboards')

        new(
          container: container,
          title: config['title'],
          slug: name,
          description: config['description'],
          schema_version: config['version'],
          panels: ProductAnalytics::Panel.from_data(config['panels'], config_project),
          user_defined: false,
          config_project: config_project
        )
      end
    end

    def self.value_stream_dashboard(container, config_project)
      return [] unless container.value_streams_dashboard_available?

      VALUE_STREAM_DASHBOARD_LIST.map do |name|
        config = load_yaml_dashboard_config(name, 'ee/lib/gitlab/analytics/value_stream_dashboard/dashboards')

        new(
          container: container,
          title: config['title'],
          slug: name,
          description: config['description'],
          schema_version: config['version'],
          panels: ProductAnalytics::Panel.from_data(config['panels'], config_project),
          user_defined: false,
          config_project: config_project
        )
      end
    end

    def self.has_dashboards?(container)
      container.product_analytics_enabled? || container.value_streams_dashboard_available?
    end

    def self.builtin_dashboards(container, config_project)
      return [] unless has_dashboards?(container)

      builtin = []

      builtin << product_analytics_dashboards(container, config_project)
      builtin << value_stream_dashboard(container, config_project)

      builtin
    end

    def ==(other)
      slug == other.slug
    end
  end
end
