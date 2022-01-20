# frozen_string_literal: true

module EE
  module GoogleCloud
    module CreateServiceAccountsService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      private

      def existing_environments
        strong_memoize(:environment) do
          Environments::EnvironmentsFinder.new(project, current_user, name: environment_name).execute
        end
      end

      def environment
        strong_memoize(:environment) do
          existing_environments.first
        end
      end

      override :environment_protected?
      def environment_protected?
        environment ? environment.protected? : false
      end
    end
  end
end
