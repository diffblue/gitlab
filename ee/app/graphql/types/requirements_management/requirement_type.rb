# frozen_string_literal: true

module Types
  module RequirementsManagement
    class RequirementType < BaseObject
      graphql_name 'Requirement'
      description 'Represents a requirement'

      authorize :read_requirement

      expose_permissions Types::PermissionTypes::Requirement

      field :id, GraphQL::Types::ID, null: false,
            description: 'ID of the requirement.'

      field :iid, GraphQL::Types::ID, null: false,
            description: 'Internal ID of the requirement.'

      field :title, GraphQL::Types::String, null: true,
            description: 'Title of the requirement.'
      markdown_field :title_html, null: true

      field :description, GraphQL::Types::String, null: true,
            description: 'Description of the requirement.'
      markdown_field :description_html, null: true

      field :state, RequirementsManagement::RequirementStateEnum, null: false,
            description: 'State of the requirement.'

      field :last_test_report_state, RequirementsManagement::TestReportStateEnum, null: true,
            description: 'Latest requirement test report state.'

      field :last_test_report_manually_created,
            GraphQL::Types::Boolean,
            method: :last_test_report_manually_created?,
            null: true,
            description: 'Indicates if latest test report was created by user.'

      field :project, ProjectType, null: false,
            description: 'Project to which the requirement belongs.'

      field :author, UserType, null: false,
            description: 'Author of the requirement.'

      field :test_reports, TestReportType.connection_type, null: true, complexity: 5,
            description: 'Test reports of the requirement.',
            resolver: Resolvers::RequirementsManagement::TestReportsResolver

      field :created_at, Types::TimeType, null: false,
            description: 'Timestamp of when the requirement was created.'

      field :updated_at, Types::TimeType, null: false,
            description: 'Timestamp of when the requirement was last updated.'

      def project
        Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
      end

      def author
        Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
      end
    end
  end
end
