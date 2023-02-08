# frozen_string_literal: true

module ProductAnalytics
  class Panel
    attr_reader :title, :grid_attributes, :visualization, :project

    def self.from_data(panel_yaml, project)
      panel_yaml.map do |panel|
        new(
          title: panel['title'],
          project: project,
          grid_attributes: panel['gridAttributes'],
          visualization: panel['visualization']
        )
      end
    end

    def initialize(title:, grid_attributes:, visualization:, project:)
      @title = title
      @project = project
      @grid_attributes = grid_attributes
      @visualization = ::ProductAnalytics::Visualization.from_data(data: visualization, project: project)
    end
  end
end
