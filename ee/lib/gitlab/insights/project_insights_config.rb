# frozen_string_literal: true

module Gitlab
  module Insights
    class ProjectInsightsConfig
      attr_reader :project, :insights_config

      def initialize(project:, insights_config:)
        @project = project
        @insights_config = insights_config_without_invalid_entries(insights_config.deep_dup)
      end

      def filtered_config
        @filtered_config ||= insights_config.each_with_object({}) do |(page_identifier, page_config), new_config|
          charts = Array(page_config[:charts])
            .select { |chart| project_is_not_filtered_out?(chart) && feature_for_chart_enabled?(chart) }

          new_config[page_identifier] = page_config.merge(charts: charts) if charts.any?
        end
      end

      def notice_text
        if filtered_config != insights_config
          s_('Insights|Some items are not visible beacuse the project was filtered out in the insights.yml file (see the projects.only config in the YAML file or the enabled project features (issues, merge requests) in the project settings).')
        end
      end

      private

      def includes_project?(project_ids_or_paths)
        project_ids_or_paths.any? { |item| item == project.id || item == project.full_path }
      end

      # filtering out leftover YAML anchor keys
      def insights_config_without_invalid_entries(config)
        config.reject { |_, page_config| page_config[:title].nil? && page_config[:charts].nil? }
      end

      def project_is_not_filtered_out?(chart)
        project_ids_or_paths = Array(chart.dig(:projects, :only))

        project_ids_or_paths.empty? || includes_project?(project_ids_or_paths)
      end

      def feature_for_chart_enabled?(chart)
        issuable_type = chart.dig(:query, :params, :issuable_type) || chart.dig(:query, :issuable_type)

        case issuable_type
        when 'issue'
          project.issues_enabled?
        when 'merge_request'
          project.merge_requests_enabled?
        else
          true
        end
      end
    end
  end
end
