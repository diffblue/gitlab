# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        class TimeToRestoreService < BaseDoraSummary
          def title
            s_('CycleAnalytics|Time to Restore Service')
          end

          def links
            helpers = Gitlab::Routing.url_helpers
            namespace = @stage.namespace

            dashboard_link =
              if namespace.is_a?(::Group)
                helpers.group_analytics_ci_cd_analytics_path(namespace, tab: 'time-to-restore-service')
              else
                helpers.charts_project_pipelines_path(namespace.project, chart: 'time-to-restore-service')
              end

            [
              {
                "name" => _('Time to Restore Service'),
                "url" => dashboard_link,
                "label" => s_('ValueStreamAnalytics|Dashboard')
              },
              {
                "name" => _('Time to Restore Service'),
                "url" => helpers.help_page_path('user/analytics/index', anchor: 'time-to-restore-service'),
                "docs_link" => true,
                "label" => s_('ValueStreamAnalytics|Go to docs')
              }
            ]
          end

          private

          def metric_key
            'time_to_restore_service'
          end
        end
      end
    end
  end
end
