# frozen_string_literal: true

module Resolvers
  module SecurityReport
    class FindingReportsComparerResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type ::Types::Security::FindingReportsComparerType, null: true

      authorize :read_security_resource
      authorizes_object!

      argument :report_type, Types::Security::ComparableReportTypeEnum,
        required: true,
        description: 'Filter vulnerability findings by report type.'

      def resolve(report_type:)
        # Necessary to use project as actor in FF check
        context[:project] = object.project

        ::Security::MergeRequestSecurityReportGenerationService.execute(object, report_type)
      end
    end
  end
end
