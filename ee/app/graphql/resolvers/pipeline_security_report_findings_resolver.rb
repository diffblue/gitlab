# frozen_string_literal: true

module Resolvers
  class PipelineSecurityReportFindingsResolver < BaseResolver
    type ::Types::PipelineSecurityReportFindingType, null: true

    alias_method :pipeline, :object

    argument :report_type, [GraphQL::Types::String],
             required: false,
             description: 'Filter vulnerability findings by report type.'

    argument :severity, [GraphQL::Types::String],
             required: false,
             description: 'Filter vulnerability findings by severity.'

    argument :scanner, [GraphQL::Types::String],
             required: false,
             description: 'Filter vulnerability findings by Scanner.externalId.'

    argument :state, [Types::VulnerabilityStateEnum],
             required: false,
             description: 'Filter vulnerability findings by state.'

    def resolve(**args)
      Security::PipelineVulnerabilitiesFinder.new(pipeline: pipeline, params: args).execute.findings
    end
  end
end
