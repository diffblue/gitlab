# frozen_string_literal: true

module Resolvers
  module SecurityReport
    class FindingResolver < BaseResolver
      type ::Types::PipelineSecurityReportFindingType, null: true

      alias_method :pipeline, :object

      argument :uuid, GraphQL::Types::String,
               required: true,
               description: 'UUID of the security report finding.'

      def resolve(**args)
        Security::FindingsFinder.new(pipeline, params: { uuid: args[:uuid], scope: 'all' }).execute&.findings&.first
      end
    end
  end
end
