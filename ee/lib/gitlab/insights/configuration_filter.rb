# frozen_string_literal: true

module Gitlab
  module Insights
    class ConfigurationFilter
      attr_reader :insights_entity, :user, :config

      def initialize(insights_entity:, config:, user:)
        @insights_entity = insights_entity
        @config = config
        @user = user
      end

      def execute
        return config if Ability.allowed?(user, :read_dora4_analytics, insights_entity)

        config.each_with_object({}) do |(dashboard, config), new_config|
          charts = Array(config[:charts])
            .select { |chart| !has_dora_data_source?(chart) }

          new_config[dashboard] = config.merge(charts: charts) if charts.any?
        end
      end

      private

      def has_dora_data_source?(chart)
        data_source = chart.dig(:query, :data_source)

        data_source == 'dora'
      end
    end
  end
end
