# frozen_string_literal: true

module Types
  module Admin
    module CloudLicenses
      # rubocop: disable Graphql/AuthorizeTypes
      class LicenseHistoryEntryType < BaseObject
        graphql_name 'LicenseHistoryEntry'
        description 'Represents an entry from the Cloud License history'

        include ::Types::Admin::CloudLicenses::LicenseType
      end
    end
  end
end
