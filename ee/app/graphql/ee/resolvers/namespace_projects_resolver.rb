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

        argument :sbom_component_id, ::GraphQL::Types::ID,
                 required: false,
                 default_value: nil,
                 description: 'Return only the projects related to the specified SBOM component.'
      end

      private

      override :finder_params
      def finder_params(args)
        super(args).merge(
          args.slice(:has_vulnerabilities, :has_code_coverage, :compliance_framework_filters, :sbom_component_id)
        )
      end
    end
  end
end
