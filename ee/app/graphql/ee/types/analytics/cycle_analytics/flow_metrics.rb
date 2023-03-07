# frozen_string_literal: true

module EE
  module Types
    module Analytics
      module CycleAnalytics
        module FlowMetrics
          extend ActiveSupport::Concern

          class_methods do
            extend ::Gitlab::Utils::Override

            override :[]
            def [](context = :project)
              klass = super
              # Extending the dynamically generated class with two more fields.
              klass.class_eval do
                field :lead_time,
                  ::Types::Analytics::CycleAnalytics::MetricType,
                  null: true,
                  description: 'Median time from when the issue was created to when it was closed.',
                  resolver: ::Resolvers::Analytics::CycleAnalytics::LeadTimeResolver[context]

                field :cycle_time,
                  ::Types::Analytics::CycleAnalytics::MetricType,
                  null: true,
                  description: 'Median time from first commit to issue closed',
                  resolver: ::Resolvers::Analytics::CycleAnalytics::CycleTimeResolver[context]
              end

              klass
            end
          end
        end
      end
    end
  end
end
