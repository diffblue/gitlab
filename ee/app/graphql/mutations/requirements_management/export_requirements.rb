# frozen_string_literal: true

module Mutations
  module RequirementsManagement
    class ExportRequirements < BaseMutation
      include FindsProject
      include CommonRequirementArguments

      graphql_name 'ExportRequirements'

      authorize :export_requirements

      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: 'Full project path the requirements are associated with.'

      argument :selected_fields, [GraphQL::Types::String],
               required: false,
               description: 'List of selected requirements fields to be exported.'

      def ready?(**args)
        if args[:selected_fields].present?
          invalid_fields =
            ::RequirementsManagement::MapExportFieldsService.new(args[:selected_fields]).invalid_fields

          if invalid_fields.any?
            message = "The following fields are incorrect: #{invalid_fields.join(', ')}."\
              " See https://docs.gitlab.com/ee/user/project/requirements/#exported-csv-file-format"\
              " for permitted fields."
            raise Gitlab::Graphql::Errors::ArgumentError, message
          end
        end

        super
      end

      def resolve(args)
        project_path = args.delete(:project_path)
        project = authorized_find!(project_path)

        IssuableExportCsvWorker.perform_async(:requirement, current_user.id, project.id, args)

        {
          errors: []
        }
      end
    end
  end
end
