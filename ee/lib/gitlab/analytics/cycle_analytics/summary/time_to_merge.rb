# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module Summary
        class TimeToMerge < BaseTime
          def title
            _('Time to Merge')
          end

          def self.start_event_identifier
            :merge_request_created
          end

          def self.end_event_identifier
            :merge_request_merged
          end

          def links
            namespace = @stage.namespace
            return [] if namespace.is_a?(::Group)

            helpers = Gitlab::Routing.url_helpers
            dashboard_link = helpers.project_analytics_merge_request_analytics_path(namespace.project)

            [
              { "name" => title, "url" => dashboard_link,
                "label" => s_('ValueStreamAnalytics|Merge request analytics') },
              { "name" => title,
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
