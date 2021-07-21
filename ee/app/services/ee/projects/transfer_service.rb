# frozen_string_literal: true

module EE
  module Projects
    module TransferService
      extend ::Gitlab::Utils::Override

      private

      override :execute_system_hooks
      def execute_system_hooks
        super

        EE::Audit::ProjectChangesAuditor.new(current_user, project).execute

        ::Geo::RepositoryRenamedEventStore.new(
          project,
          old_path: project.path,
          old_path_with_namespace: old_path
        ).create!
      end

      override :transfer_missing_group_resources
      def transfer_missing_group_resources(group)
        super

        ::Epics::TransferService.new(current_user, group, project).execute
      end

      override :post_update_hooks
      def post_update_hooks(project)
        super

        update_elasticsearch_hooks
      end

      def update_elasticsearch_hooks
        return unless ::Gitlab::CurrentSettings.elasticsearch_limit_indexing?

        # handle when project is moved to a new namespace with different elasticsearch settings
        # than the old namespace
        if old_namespace.use_elasticsearch? != new_namespace.use_elasticsearch?
          project.invalidate_elasticsearch_indexes_cache!

          ::Elastic::ProcessInitialBookkeepingService.backfill_projects!(project) if project.maintaining_elasticsearch?
        end
      end

      override :remove_paid_features
      def remove_paid_features
        revoke_project_access_tokens
      end

      def revoke_project_access_tokens
        return if new_namespace.feature_available_non_trial?(:resource_access_token)

        PersonalAccessTokensFinder
          .new(user: project.bots, impersonation: false)
          .execute
          .update_all(revoked: true)
      end
    end
  end
end
