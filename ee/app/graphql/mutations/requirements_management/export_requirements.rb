# frozen_string_literal: true

module Mutations
  module RequirementsManagement
    class ExportRequirements < BaseMutation
      graphql_name 'ExportRequirements'

      include FindsProject
      include CommonRequirementArguments

      authorize :export_requirements

      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: 'Full project path the requirements are associated with.'

      argument :selected_fields, [GraphQL::Types::String],
               required: false,
               description: 'List of selected requirements fields to be exported.'

      def ready?(**args)
        if args[:selected_fields].present?
          export_service = ::RequirementsManagement::ExportCsvService.new(nil, nil, args[:selected_fields])
          invalid_fields = export_service.invalid_fields

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

        # rubocop:disable CodeReuse/Worker
        IssuableExportCsvWorker.perform_async(:requirement, current_user.id, project.id, args)
        # rubocop:enable CodeReuse/Worker

        {
          errors: []
        }
      end
    end
  end
end
