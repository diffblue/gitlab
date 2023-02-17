# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        class ChangeFailureRate < BaseDoraSummary
          def title
            s_('CycleAnalytics|Change Failure Rate')
          end

          def unit
            '%'
          end

          def value
            @value ||= begin
              metric = dora_metric

              if metric[:status] == :success
                metric_value = metric[:data].first[metric_key]

                metric_value ? (metric_value * 100).round(2) : 0
              else
                nil # nil signals the summary class to not even try to serialize the result
              end
            end
          end

          def links
            helpers = Gitlab::Routing.url_helpers

            dashboard_link =
              if @stage.namespace.is_a?(::Group)
                helpers.group_analytics_ci_cd_analytics_path(@stage.namespace, tab: 'change-failure-rate')
              else
                helpers.charts_project_pipelines_path(@stage.namespace.project, chart: 'change-failure-rate')
              end

            [
              {
                "name" => _('Change Failure Rate'),
                "url" => dashboard_link,
                "label" => s_('ValueStreamAnalytics|Dashboard')
              },
              {
                "name" => _('Change Failure Rate'),
                "url" => helpers.help_page_path('user/analytics/index', anchor: 'change-failure-rate'),
                "docs_link" => true,
                "label" => s_('ValueStreamAnalytics|Go to docs')
              }
            ]
          end

          private

          def metric_key
            'change_failure_rate'
          end
        end
      end
    end
  end
end
