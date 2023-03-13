# frozen_string_literal: true

# rubocop:disable Graphql/ResolverType (inherited from Resolvers::Analytics::CycleAnalytics::BaseIssueResolver)
module Resolvers
  module Analytics
    module CycleAnalytics
      class BaseStageResolver < BaseIssueResolver
        def resolve(**args)
          metric = self.class::METRIC_CLASS.new(
            stage: ::Analytics::CycleAnalytics::Stage.new(namespace: object),
            current_user: current_user,
            options: process_params(args)
          )

          formatted_data(metric)
        end

        def authorized?(*)
          ::Gitlab::Analytics::CycleAnalytics.licensed?(object) && ::Gitlab::Analytics::CycleAnalytics.allowed?(
            current_user, object)
        end

        private

        def process_params(params)
          params[:assignee_username] = params.delete(:assignee_usernames) if params[:assignee_usernames]
          params[:label_name] = params.delete(:label_names) if params[:label_names]
          params[:projects] = params[:project_ids] if params[:project_ids]
          params[:use_aggregated_data_collector] = true

          params
        end

        def formatted_data(metric)
          value = metric.raw_value

          {
            value: value,
            unit: n_('day', 'days', value),
            links: metric.links
          }
        end
      end
    end
  end
end
# rubocop:enable Graphql/ResolverType
