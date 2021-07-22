# frozen_string_literal: true

module Ci
  module Minutes
    class UpdateProjectAndNamespaceUsageService
      include Gitlab::Utils::StrongMemoize

      def initialize(project_id, namespace_id)
        @project_id = project_id
        @namespace_id = namespace_id
        # TODO(issue 335885): Use project_id only and don't query for projects which may be deleted
        @project = Project.find_by_id(project_id)
      end

      # Updates the project and namespace usage based on the passed consumption amount
      def execute(consumption)
        legacy_track_usage_of_monthly_minutes(consumption)
        ApplicationRecord.transaction do
          track_usage_of_monthly_minutes(consumption)

          send_minutes_email_notification
        end
      end

      private

      def send_minutes_email_notification
        # `perform reset` on `project` because `Namespace#namespace_statistics` will otherwise return stale data.
        # TODO(issue 335885): Remove @project
        ::Ci::Minutes::EmailNotificationService.new(@project.reset).execute if ::Gitlab.com?
      end

      def legacy_track_usage_of_monthly_minutes(consumption)
        consumption_in_seconds = consumption.minutes.to_i

        update_legacy_project_minutes(consumption_in_seconds)
        update_legacy_namespace_minutes(consumption_in_seconds)
      end

      def track_usage_of_monthly_minutes(consumption)
        # TODO(issue 335885): Remove @project
        return unless Feature.enabled?(:ci_minutes_monthly_tracking, @project, default_enabled: :yaml)

        ::Ci::Minutes::NamespaceMonthlyUsage.increase_usage(namespace_usage, consumption) if namespace_usage
        ::Ci::Minutes::ProjectMonthlyUsage.increase_usage(project_usage, consumption) if project_usage
      end

      def update_legacy_project_minutes(consumption_in_seconds)
        if project_statistics
          ProjectStatistics.update_counters(project_statistics, shared_runners_seconds: consumption_in_seconds)
        end
      end

      def update_legacy_namespace_minutes(consumption_in_seconds)
        if namespace_statistics
          NamespaceStatistics.update_counters(namespace_statistics, shared_runners_seconds: consumption_in_seconds)
        end
      end

      def namespace_usage
        ::Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: @namespace_id)
      end

      def project_usage
        strong_memoize(:project_usage) do
          ::Ci::Minutes::ProjectMonthlyUsage.find_or_create_current(project_id: @project_id)
        rescue ActiveRecord::InvalidForeignKey
        end
      end

      def namespace_statistics
        strong_memoize(:namespace_statistics) do
          NamespaceStatistics.safe_find_or_create_by!(namespace_id: @namespace_id)
        rescue ActiveRecord::NotNullViolation, ActiveRecord::RecordInvalid
        end
      end

      def project_statistics
        strong_memoize(:project_statistics) do
          ProjectStatistics.safe_find_or_create_by!(project_id: @project_id)
        rescue ActiveRecord::NotNullViolation, ActiveRecord::RecordInvalid
        end
      end
    end
  end
end
