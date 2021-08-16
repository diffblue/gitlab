# frozen_string_literal: true

module EE
  module Ci
    module Queue
      module BuildQueueService
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        override :builds_for_shared_runner
        def builds_for_shared_runner
          # if disaster recovery is enabled, we disable quota
          if ::Feature.enabled?(:ci_queueing_disaster_recovery_disable_quota, runner, type: :ops, default_enabled: :yaml)
            super
          else
            enforce_minutes_based_on_cost_factors(super)
          end
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def enforce_minutes_based_on_cost_factors(relation)
          if strategy.use_denormalized_minutes_data?
            strategy.enforce_minutes_quota(relation)
          else
            enforce_minutes_using_legacy_data(relation)
          end
        end

        def enforce_minutes_using_legacy_data(relation)
          if strategy.use_denormalized_shared_runners_data?
            # If shared runners information is denormalized then the query does not include the join
            # with `projects` anymore, so we need to add it until we use denormalized ci minutes

            relation = relation.joins('INNER JOIN projects ON ci_pending_builds.project_id = projects.id')
          end

          visibility_relation = ::CommitStatus.where(
            projects: { visibility_level: runner.visibility_levels_without_minutes_quota })

          enforce_limits_relation = ::CommitStatus.where('EXISTS (?)', builds_check_limit)

          relation.merge(visibility_relation.or(enforce_limits_relation))
        end

        def builds_check_limit
          all_namespaces
            .joins('LEFT JOIN namespace_statistics ON namespace_statistics.namespace_id = namespaces.id')
            .where('COALESCE(namespaces.shared_runners_minutes_limit, ?, 0) = 0 OR ' \
                   'COALESCE(namespace_statistics.shared_runners_seconds, 0) < ' \
                   'COALESCE('\
                     '(namespaces.shared_runners_minutes_limit + COALESCE(namespaces.extra_shared_runners_minutes_limit, 0)), ' \
                     '(? + COALESCE(namespaces.extra_shared_runners_minutes_limit, 0)), ' \
                    '0) * 60',
                  application_shared_runners_minutes, application_shared_runners_minutes)
            .select('1')
        end

        def all_namespaces
          if traversal_ids_enabled?
            ::Namespace
              .where('namespaces.id = project_namespaces.traversal_ids[1]')
              .joins('INNER JOIN namespaces as project_namespaces ON project_namespaces.id = projects.namespace_id')
          else
            namespaces = ::Namespace.reorder(nil).where('namespaces.id = projects.namespace_id')
            ::Gitlab::ObjectHierarchy.new(namespaces).roots
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def application_shared_runners_minutes
          ::Gitlab::CurrentSettings.shared_runners_minutes
        end

        def traversal_ids_enabled?
          ::Feature.enabled?(:sync_traversal_ids, default_enabled: :yaml) &&
            ::Feature.enabled?(:traversal_ids_for_quota_calculation, type: :development, default_enabled: :yaml)
        end
      end
    end
  end
end
