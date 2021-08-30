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
        # When a project is moved to a new namespace, invalidate the ES cache if Elasticsearch limit indexing is enabled
        # and the Elasticsearch settings are different between the two namespaces. The project and all associated data
        # is indexed to make sure the namespace_ancestry field gets updated in each document.
        if ::Gitlab::CurrentSettings.elasticsearch_limit_indexing? && old_namespace.use_elasticsearch? != new_namespace.use_elasticsearch?
          project.invalidate_elasticsearch_indexes_cache!
        end

        ::Elastic::ProcessInitialBookkeepingService.backfill_projects!(project) if project.maintaining_elasticsearch?
      end

      override :remove_paid_features
      def remove_paid_features
        revoke_project_access_tokens
        delete_pipeline_subscriptions
        delete_test_cases
      end

      def revoke_project_access_tokens
        return if new_namespace.feature_available_non_trial?(:resource_access_token)

        PersonalAccessTokensFinder
          .new(user: project.bots, impersonation: false)
          .execute
          .update_all(revoked: true)
      end

      def delete_pipeline_subscriptions
        return if new_namespace.licensed_feature_available?(:ci_project_subscriptions)

        project.upstream_project_subscriptions.destroy_all # rubocop: disable Cop/DestroyAll
      end

      def delete_test_cases
        return if new_namespace.licensed_feature_available?(:quality_management)

        project.issues.with_issue_type(:test_case).delete_all
      end
    end
  end
end
