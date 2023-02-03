# frozen_string_literal: true

module Types
  module RequirementsManagement
    class TestReportType < BaseObject
      graphql_name 'TestReport'
      description 'Represents a requirement test report'

      authorize :read_work_item

      field :id, GraphQL::Types::ID, null: false, description: 'ID of the test report.'

      field :state, TestReportStateEnum, null: false, description: 'State of the test report.'

      field :author, UserType, null: true, description: 'Author of the test report.'

      field :created_at, TimeType,
        null: false, description: 'Timestamp of when the test report was created.'

      field :uses_legacy_iid, GraphQL::Types::Boolean, null: true,
        description: 'Indicates whether the test report was generated with references to legacy requirement IIDs.'

      def author
        Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
      end
    end
  end
end
