# frozen_string_literal: true

module Resolvers
  module Environments
    class ProtectedEnvironmentsResolver < BaseResolver
      type Types::ProtectedEnvironmentType, null: true

      def resolve
        return unless object.present? && object.is_a?(::Environment)

        find_protected_environments
      end

      private

      def find_protected_environments
        BatchLoader::GraphQL.for(object).batch do |environments, loader|
          Preloaders::Environments::ProtectedEnvironmentPreloader.new(environments)
            .execute(protected_environment_associations)

          environments.each do |environment|
            loader.call(environment, environment.associated_protected_environments)
          end
        end
      end

      def protected_environment_associations
        {
          deploy_access_levels: authorizable_associations,
          approval_rules: authorizable_associations
        }
      end

      def authorizable_associations
        { user: [], group: [] }
      end
    end
  end
end
