# frozen_string_literal: true

module Types
  module RequirementsManagement
    class RequirementType < BaseObject
      graphql_name 'Requirement'
      description 'Represents a requirement'

      authorize :read_requirement

      expose_permissions Types::PermissionTypes::Requirement

      field :id, GraphQL::Types::ID, null: false, description: 'ID of the requirement.'

      field :iid, GraphQL::Types::ID, null: false,
        description: 'Internal ID of the requirement.',
        deprecated: { reason: 'Use work_item_iid instead', milestone: '15.8' }

      field :work_item_iid, GraphQL::Types::ID, null: false,
                                                method: :work_item_iid,
                                                description: 'Work item IID of the requirement, '\
                                                             'will replace current IID as identifier soon.'

      field :title, GraphQL::Types::String, null: true, description: 'Title of the requirement.'

      field :title_html, GraphQL::Types::String,
        description: 'GitLab Flavored Markdown rendering of `title`.',
        complexity: 5,
        resolver_method: :title_html_resolver,
        null: true

      field :description, GraphQL::Types::String,
        null: true, description: 'Description of the requirement.'

      field :description_html, GraphQL::Types::String,
        description: 'GitLab Flavored Markdown rendering of `description`.',
        complexity: 5,
        resolver_method: :description_html_resolver,
        null: true

      field :state, RequirementsManagement::RequirementStateEnum,
        null: false, description: 'State of the requirement.'

      field :last_test_report_state, RequirementsManagement::TestReportStateEnum,
        null: true, description: 'Latest requirement test report state.'

      field :last_test_report_manually_created, GraphQL::Types::Boolean,
        method: :last_test_report_manually_created?, null: true,
        description: 'Indicates if latest test report was created by user.'

      field :project, ProjectType,
        null: false, description: 'Project to which the requirement belongs.'

      field :author, UserType,
        null: false, description: 'Author of the requirement.'

      field :test_reports, TestReportType.connection_type,
        null: true, complexity: 5,
        resolver: Resolvers::RequirementsManagement::TestReportsResolver,
        description: 'Test reports of the requirement.'

      field :created_at, Types::TimeType,
        null: false, description: 'Timestamp of when the requirement was created.'

      field :updated_at, Types::TimeType,
        null: false, description: 'Timestamp of when the requirement was last updated.'

      def title_html_resolver
        html_for(:title)
      end

      def description_html_resolver
        html_for(:description)
      end

      # We need to delegate cached html fields to requirement_issue object
      # until this endpoint gets deprecated. This method is a copy of
      # the dynamically defined at Gitlab::GraphqL::MarkdownField#markdown_field.
      def html_for(field)
        markdown_object = block_given? ? yield(object) : object

        # We need to `dup` the context so the MarkdownHelper doesn't modify it
        ::MarkupHelper.markdown_field(markdown_object.requirement_issue, field, context.to_h.dup)
      end

      def project
        Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
      end

      def author
        Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
      end

      def work_item_iid
        object.requirement_issue.iid
      end
    end
  end
end
