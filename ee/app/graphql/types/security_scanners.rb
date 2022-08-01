# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class SecurityScanners < BaseObject
    graphql_name 'SecurityScanners'
    description 'Represents a list of security scanners'

    field :enabled,
          [::Types::SecurityScannerTypeEnum],
          null: true,
          description: 'List of analyzers which are enabled for the project.',
          method: :enabled_scanners,
          calls_gitaly: true

    field :available,
          [::Types::SecurityScannerTypeEnum],
          null: true,
          description: 'List of analyzers which are available for the project.',
          method: :available_scanners

    field :pipeline_run,
          [::Types::SecurityScannerTypeEnum],
          null: true,
          description: 'List of analyzers which ran successfully in the latest pipeline.',
          method: :scanners_run_in_last_pipeline,
          calls_gitaly: true
  end
end
