# frozen_string_literal: true

module ProductAnalytics
  class Dashboard
    attr_reader :title, :description, :schema_version, :panels, :project, :slug, :path

    DASHBOARD_ROOT_LOCATION = '.gitlab/product_analytics/dashboards'

    def self.for_project(project)
      root_trees = project.repository.tree(:head, DASHBOARD_ROOT_LOCATION)
      return [] unless root_trees&.entries&.any?

      root_trees.trees.delete_if { |tree| tree.name == 'visualizations' }.map do |tree|
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

    def initialize(title:, description:, schema_version:, panels:, project:, slug:)
      @title = title
      @description = description
      @schema_version = schema_version
      @panels = panels
      @project = project
      @slug = slug
    end

    def ==(other)
      slug == other.slug
    end
  end
end
