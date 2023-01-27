# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # rubocop:disable Graphql/AuthorizeTypes
      class TestReportsType < BaseObject
        graphql_name 'WorkItemWidgetTestReports'
        description 'Represents a test reports widget'

        implements Types::WorkItems::WidgetInterface

        field :test_reports, ::Types::RequirementsManagement::TestReportType.connection_type,
          null: true,
          description: 'Test reports of the work item.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
