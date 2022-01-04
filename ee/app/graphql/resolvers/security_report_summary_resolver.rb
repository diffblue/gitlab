# frozen_string_literal: true

module Resolvers
  class SecurityReportSummaryResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type Types::SecurityReportSummaryType, null: true
    authorize :read_security_resource
    extras [:lookahead]

    alias_method :pipeline, :object

    def resolve(lookahead:)
      return unless authorized_resource?(pipeline.project)

      Security::ReportSummaryService.new(
        pipeline,
        selection_information(lookahead)
      ).execute
    end

    private

    def selection_information(lookahead)
      lookahead.selections.each_with_object({}) do |report_type, response|
        next if report_type.name == :__typename

        response[report_type.name.to_sym] = report_type.selections.map(&:name) - [:__typename] # ignore __typename meta field
      end
    end
  end
end
