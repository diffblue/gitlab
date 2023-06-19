# frozen_string_literal: true

module ProductAnalytics
  class Panel
    attr_reader :title, :grid_attributes, :visualization, :project, :query_overrides

    def self.from_data(panel_yaml, project)
      panel_yaml.map do |panel|
        new(
          title: panel['title'],
          project: project,
          grid_attributes: panel['gridAttributes'],
          query_overrides: panel['queryOverrides'],
          visualization: panel['visualization']
        )
      end
    end

    def initialize(title:, grid_attributes:, visualization:, project:, query_overrides:)
      @title = title
      @project = project
      @grid_attributes = grid_attributes
      @query_overrides = query_overrides
      @visualization = ::ProductAnalytics::Visualization.from_data(data: visualization, project: project)
    end
  end
end
