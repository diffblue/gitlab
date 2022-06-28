# frozen_string_literal: true

module API
  module Entities
    class Environment < Entities::EnvironmentBasic
      include RequestAwareEntity
      include Gitlab::Utils::StrongMemoize

      expose :tier
      expose :project, using: Entities::BasicProjectDetails
      expose :last_deployment, using: Entities::Deployment, if: { last_deployment: true }
      expose :state

      private

      alias_method :environment, :object

      def can_read_pod_logs?
        strong_memoize(:can_read_pod_logs) do
          current_user&.can?(:read_pod_logs, environment.project)
        end
      end

      def cluster
        strong_memoize(:cluster) do
          environment&.last_deployment&.cluster
        end
      end

      def current_user
        options[:current_user]
      end
    end
  end
end
