# frozen_string_literal: true

module Types
  module Dast
    class ScanMethodTypeEnum < BaseEnum
      graphql_name 'DastScanMethodType'
      description 'Scan method to be used by the scanner.'

      value 'WEBSITE', description: 'Website scan method.', value: 'site'
      value 'OPENAPI', description: 'OpenAPI scan method.', value: 'openapi'
      value 'HAR', description: 'HAR scan method.', value: 'har'
      value 'POSTMAN_COLLECTION', description: 'Postman scan method.', value: 'postman'
      value 'GRAPHQL', description: 'GraphQL scan method.', value: 'graphql'
    end
  end
end
