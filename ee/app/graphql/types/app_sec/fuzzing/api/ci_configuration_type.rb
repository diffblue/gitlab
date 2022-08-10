# frozen_string_literal: true

module Types
  module AppSec
    module Fuzzing
      module API
        # rubocop: disable Graphql/AuthorizeTypes
        class CiConfigurationType < BaseObject
          graphql_name 'ApiFuzzingCiConfiguration'
          description 'Data associated with configuring API fuzzing scans in GitLab CI'

          field :scan_modes, [ScanModeEnum],
            null: true, description: 'All available scan modes.'

          field :scan_profiles, [ScanProfileType],
            null: true, description: 'All default scan profiles.'
        end
        # rubocop: enable Graphql/AuthorizeTypes
      end
    end
  end
end
