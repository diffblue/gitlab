# frozen_string_literal: true

module Analytics
  module ProductAnalytics
    class ProjectUsageData
      def initialize(project_id:)
        @project = Project.find(project_id)
      end

      def events_stored_count(month: Time.current.month, year: Time.current.year)
        response = Gitlab::HTTP.get(
          usage_url(year, month),
          allow_local_requests: true,
          timeout: 10
        )

        Gitlab::Json.parse(response.body)['result']
      end

      private

      def settings
        ::ProductAnalytics::Settings.for_project(@project)
      end

      def usage_url(year, month)
        "#{settings.product_analytics_configurator_connection_string}/usage/gitlab_project_#{@project.id}/#{year}/#{month}" # rubocop:disable Layout/LineLength
      end
    end
  end
end
