# frozen_string_literal: true

module ProductAnalytics
  class Funnel
    include ActiveModel::Validations

    attr_accessor :name, :project, :seconds_to_convert, :config_project

    FUNNELS_ROOT_LOCATION = '.gitlab/analytics/funnels'

    validates :name, presence: true
    validates :seconds_to_convert, numericality: { only_integer: true, greater_than: 0 }

    def self.for_project(project)
      config_project = project.analytics_dashboards_configuration_project || project
      root_trees = config_project.repository.tree(:head, FUNNELS_ROOT_LOCATION)
      return [] unless root_trees&.entries&.any?

      root_trees.entries.filter_map do |tree|
        config = YAML.safe_load(
          config_project.repository.blob_data_at(config_project.repository.root_ref_sha, tree.path)
        )

        next unless config['name'] && config['seconds_to_convert'] && config['steps']

        new(
          name: config['name'],
          project: project,
          config_project: config_project,
          seconds_to_convert: config['seconds_to_convert'],
          config_path: tree.path
        )
      end
    end

    def initialize(name:, project:, seconds_to_convert:, config_path:, config_project:)
      @name = name.parameterize.underscore
      @project = project
      @seconds_to_convert = seconds_to_convert
      @config_path = config_path
      @config_project = config_project
    end

    def steps
      config = YAML.safe_load(
        project.repository.blob_data_at(project.repository.root_ref_sha, @config_path)
      )

      config['steps'].map do |step|
        ProductAnalytics::FunnelStep.new(
          name: step['name'],
          target: step['target'],
          action: step['action'],
          funnel: self
        )
      end
    end

    def to_sql
      <<-SQL
      SELECT
        (SELECT max(derived_tstamp) FROM snowplow_events) as x,
        windowFunnel(#{@seconds_to_convert})(toDateTime(derived_tstamp), #{steps.filter_map(&:step_definition).join(', ')}) as step
        FROM gitlab_project_#{project.id}.snowplow_events
      SQL
    end
  end
end
