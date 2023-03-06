# frozen_string_literal: true

module EE
  module Resolvers
    module NamespaceProjectsResolver
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        argument :compliance_framework_filters, ::Types::ComplianceManagement::ComplianceFrameworkFilterInputType,
                 required: false,
                 description: 'Filters applied when selecting a compliance framework.'

        argument :has_code_coverage, GraphQL::Types::Boolean,
                 required: false,
                 default_value: false,
                 description: 'Returns only the projects which have code coverage.'

        argument :has_vulnerabilities, GraphQL::Types::Boolean,
                 required: false,
                 default_value: false,
                 description: 'Returns only the projects which have vulnerabilities.'
      end

      private

      override :finder_params
      def finder_params(args)
        super(args).merge(
          has_vulnerabilities: args.dig(:has_vulnerabilities),
          has_code_coverage: args.dig(:has_code_coverage),
          compliance_framework_filters: args.dig(:compliance_framework_filters))
      end
    end
  end
end
