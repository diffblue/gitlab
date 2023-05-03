# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        class LeadTime < BaseTime
          def title
            _('Lead Time')
          end

          def self.start_event_identifier
            :issue_created
          end

          def self.end_event_identifier
            :issue_closed
          end

          def count
            data_collector.count.to_i
          end

          def links
            helpers = Gitlab::Routing.url_helpers

            dashboard_link =
              if @stage.namespace.is_a?(::Group)
                helpers.group_issues_analytics_path(@stage.namespace)
              else
                helpers.project_analytics_issues_analytics_path(@stage.namespace.project)
              end

            [
              { "name" => _('Lead Time'), "url" => dashboard_link, "label" => s_('ValueStreamAnalytics|Dashboard') },
              { "name" => _('Lead Time'),
                "url" => helpers.help_page_path('user/analytics/index', anchor: 'definitions'),
                "docs_link" => true,
                "label" => s_('ValueStreamAnalytics|Go to docs') }
            ]
          end
        end
      end
    end
  end
end
