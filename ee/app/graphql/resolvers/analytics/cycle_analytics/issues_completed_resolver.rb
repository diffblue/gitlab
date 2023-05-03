# frozen_string_literal: true

# rubocop:disable Graphql/ResolverType (inherited from Resolvers::Analytics::CycleAnalytics::BaseStageResolver)
module Resolvers
  module Analytics
    module CycleAnalytics
      class IssuesCompletedResolver < BaseStageResolver
        METRIC_CLASS = Gitlab::Analytics::CycleAnalytics::Summary::LeadTime

        private

        def formatted_data(metric)
          value = metric.count

          {
            value: value,
            title: _('Issues Completed'),
            unit: n_('issue', 'issues', value),
            identifier: :issues_completed,
            links: metric.links
          }
        end
      end
    end
  end
end
# rubocop:enable Graphql/ResolverType
