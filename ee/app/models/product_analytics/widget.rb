# frozen_string_literal: true

module ProductAnalytics
  class Widget
    attr_reader :title, :grid_attributes

    def self.from_data(widget_yaml)
      widget_yaml.map do |widget|
        new(
          title: widget['title'],
          grid_attributes: widget['gridAttributes']
        )
      end
    end

    def initialize(title:, grid_attributes:)
      @title = title
      @grid_attributes = grid_attributes
    end
  end
end
