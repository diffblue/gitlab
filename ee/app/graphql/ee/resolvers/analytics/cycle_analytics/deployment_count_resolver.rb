# frozen_string_literal: true

module EE
  module Resolvers
    module Analytics
      module CycleAnalytics
        module DeploymentCountResolver
          extend ::Gitlab::Utils::Override

          private

          override :count
          def count(args)
            # Only licensed customers can get the aggregated DORA data (premium, ultimate)
            return super unless ::Gitlab::Analytics::CycleAnalytics.licensed?(object)

            projects_query = object.is_a?(Group) ? object.all_projects : object.project
            projects_query = projects_query.id_in(args[:project_ids]) if args[:project_ids]

            environments = ::Environment.for_project(projects_query).for_tier(:production)

            ::Dora::DailyMetrics
              .for_environments(environments)
              .in_range_of(args[:from].to_date, args[:to].to_date)
              .sum(:deployment_frequency)
          end
        end
      end
    end
  end
end
