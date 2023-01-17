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
      pure_finder = ::Security::PureFindingsFinder.new(pipeline, params: args)
      return pure_finder.execute if pure_finder.available?

      # This finder class has been deprecated and will be removed by
      # https://gitlab.com/gitlab-org/gitlab/-/issues/334488.
      # We can remove the rescue block while addressing that issue.
      ::Security::PipelineVulnerabilitiesFinder.new(pipeline: pipeline, params: args).execute.findings
    rescue ::Security::PipelineVulnerabilitiesFinder::ParseError
      []
    end
  end
end
