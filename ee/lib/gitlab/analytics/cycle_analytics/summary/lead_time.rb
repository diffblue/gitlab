# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        class LeadTime < BaseTime
          def title
            _('Lead Time')
          end

          def start_event_identifier
            :issue_created
          end

          def end_event_identifier
            :issue_closed
          end

          def links
            helpers = Gitlab::Routing.url_helpers

            dashboard_link =
              if @stage.parent.is_a?(::Group)
                helpers.group_analytics_ci_cd_analytics_path(@stage.parent, tab: 'lead-time')
              else
                helpers.charts_project_pipelines_path(@stage.parent, chart: 'lead-time')
              end

            [
              { "name" => _('Lead Time'), "url" => dashboard_link, "label" => s_('ValueStreamAnalytics|Dashboard') },
              { "name" => _('Lead Time'), "url" => helpers.help_page_path('user/analytics/index', anchor: 'definitions'), "docs_link" => true, "label" => s_('ValueStreamAnalytics|Go to docs') }
            ]
          end
        end
      end
    end
  end
end
