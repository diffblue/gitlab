# frozen_string_literal: true

module EE
  module Mutations
    module Issues
      module Create
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          include ::Mutations::Issues::CommonEEMutationArguments

          argument :epic_id, ::Types::GlobalIDType[::Epic],
                   required: false,
                   description: 'ID of an epic to associate the issue with.'
          argument :iteration_id, ::Types::GlobalIDType[::Iteration],
                   required: false,
                   description: 'Global iteration ID. Mutually exlusive argument with `iterationWildcardId`.'
          argument :iteration_wildcard_id, ::Types::IssueCreationIterationWildcardIdEnum,
                   required: false,
                   description: 'Iteration wildcard ID. Supported values are: `CURRENT`.' \
                                ' Mutually exclusive argument with `iterationId`.' \
                                ' iterationCadenceId also required when this argument is provided.'
          argument :iteration_cadence_id, ::Types::GlobalIDType[::Iterations::Cadence],
                   required: false,
                   description: 'Global iteration cadence ID. Required when `iterationWildcardId` is provided.'
        end

        override :resolve
        def resolve(**args)
          super
        rescue ActiveRecord::RecordNotFound => e
          { errors: [e.message], issue: nil }
        rescue ::Issues::BaseService::IterationAssignmentError => e
          raise(
            ::Gitlab::Graphql::Errors::ArgumentError,
            transform_field_names(e.message)
          )
        end

        private

        override :build_create_issue_params
        def build_create_issue_params(params, project)
          params[:epic_id] = params[:epic_id]&.model_id if params.key?(:epic_id)

          handle_iteration_params(params, project)

          super
        end

        def handle_iteration_params(params, project)
          group = project.group
          return unless group && group.licensed_feature_available?(:iterations)

          params[:iteration_id] = params[:iteration_id]&.model_id
          params[:iteration_cadence_id] = params[:iteration_cadence_id]&.model_id
        end

        def name_mappings
          {
            'iteration_wildcard_id' => 'iterationWildcardId',
            'iteration_cadence_id' => 'iterationCadenceId',
            'iteration_id' => 'iterationId'
          }
        end

        def transform_field_names(message)
          name_mappings.reduce(message) do |transformed_message, (k, v)|
            transformed_message.gsub(k, v)
          end
        end
      end
    end
  end
end
