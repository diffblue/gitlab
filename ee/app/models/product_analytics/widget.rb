# frozen_string_literal: true

module ProductAnalytics
  class Widget
    attr_reader :title, :grid_attributes, :visualization, :project

    def self.from_data(widget_yaml, project)
      widget_yaml.map do |widget|
        new(
          title: widget['title'],
          project: project,
          grid_attributes: widget['gridAttributes'],
          visualization: widget['visualization']
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
