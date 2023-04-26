# frozen_string_literal: true

module ProductAnalytics
  class Dashboard
    attr_reader :title, :description, :schema_version, :panels, :project, :slug, :path

    DASHBOARD_ROOT_LOCATION = '.gitlab/analytics/dashboards'

    def self.for_project(project)
      raise ArgumentError, 'Project not provided' unless project.present?

      dashboards = []

      root_trees = project.repository.tree(:head, DASHBOARD_ROOT_LOCATION)

      dashboards << local_dashboards(project, root_trees.trees) if root_trees&.trees

      dashboards << builtin_dashboards(project) if product_analytics_available?(project)

      dashboards.flatten
    end

    def initialize(title:, description:, schema_version:, panels:, project:, slug:)
      @title = title
      @description = description
      @schema_version = schema_version
      @panels = panels
      @project = project
      @slug = slug
    end

    def self.local_dashboards(project, trees)
      trees.delete_if { |tree| tree.name == 'visualizations' }.map do |tree|
        config = YAML.safe_load(
          project.repository.blob_data_at(project.repository.root_ref_sha,
                                          "#{tree.path}/#{tree.name}.yaml")
        )

        new(
          project: project,
          title: config['title'],
          slug: tree.name,
          description: config['description'],
          schema_version: config['version'],
          panels: ProductAnalytics::Panel.from_data(config['panels'], project)
        )
      end
    end

    def self.builtin_dashboards(project)
      dashboard_names = %w[audience behavior]
      dashboard_names.map do |name|
        config = YAML.safe_load(
          File.read(Rails.root.join('ee/lib/gitlab/analytics/product_analytics/dashboards', "#{name}.yaml"))
        )

        new(
          project: project,
          title: config['title'],
          slug: name,
          description: config['description'],
          schema_version: config['version'],
          panels: ProductAnalytics::Panel.from_data(config['panels'], project)
        )
      end
    end

    def self.product_analytics_available?(project)
      ::Feature.enabled?(:product_analytics_snowplow_support, project) &&
        project.product_analytics_enabled? &&
        (project.project_setting.jitsu_key || project.project_setting.product_analytics_instrumentation_key)
    end

    def ==(other)
      slug == other.slug
    end
  end
end
