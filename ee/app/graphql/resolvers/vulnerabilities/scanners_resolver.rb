# frozen_string_literal: true

module Resolvers
  module Vulnerabilities
    class ScannersResolver < VulnerabilitiesBaseResolver
      type Types::VulnerabilityScannerType, null: true

      def resolve(**args)
        return ::Vulnerabilities::Scanner.none unless vulnerable

        vulnerable
          .vulnerability_scanners
          .with_report_type
          .map { |entry| Representation::VulnerabilityScannerEntry.new(entry) }
      end
    end
  end
end
