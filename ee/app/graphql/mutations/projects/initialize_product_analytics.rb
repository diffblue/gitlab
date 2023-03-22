# frozen_string_literal: true

module Mutations
  module Projects
    class InitializeProductAnalytics < BaseMutation
      graphql_name 'ProjectInitializeProductAnalytics'

      include FindsProject

      authorize :developer_access

      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: 'Full path of the project to initialize.'

      field :project, Types::ProjectType,
            null: true,
            description: 'Project on which the initialization took place.'

      def resolve(project_path:)
        project = authorized_find!(project_path)
        service = ::ProductAnalytics::InitializeStackService.new(container: project, current_user: current_user)
                                                            .execute

        if service.success?
          {
            project: project,
            errors: []
          }
        else
          {
            project: project || nil,
            errors: [service.message]
          }
        end
      end
    end
  end
end
