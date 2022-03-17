# frozen_string_literal: true

module Mutations
  module Security
    class TrainingProviderUpdate < BaseMutation
      graphql_name 'SecurityTrainingUpdate'

      include FindsProject

      authorize :access_security_and_compliance

      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: 'Full path of the project.'

      argument :provider_id, ::Types::GlobalIDType[::Security::TrainingProvider],
               required: true,
               description: 'ID of the provider.'

      argument :is_enabled, GraphQL::Types::Boolean,
               required: true,
               description: 'Sets the training provider as enabled for the project.'

      argument :is_primary, GraphQL::Types::Boolean,
               required: false,
               description: 'Sets the training provider as primary for the project.'

      field :training, ::Types::Security::TrainingType,
            null: true,
            description: 'Represents the training entity subject to mutation.'

      def resolve(project_path:, **params)
        project = authorized_find!(project_path)
        result = ::Security::UpdateTrainingService.new(project, params).execute

        {
          training: provider_data_for(result[:training]),
          errors: Array(result[:message])
        }
      end

      private

      def provider_data_for(training)
        return unless training.provider

        training.provider.tap do |provider|
          provider.assign_attributes(is_enabled: !training.destroyed?, is_primary: !training.destroyed? && training.is_primary)
        end
      end
    end
  end
end
