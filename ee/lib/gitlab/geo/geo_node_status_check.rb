# frozen_string_literal: true

require 'action_view/helpers'

module Gitlab
  module Geo
    class GeoNodeStatusCheck
      include ActionView::Helpers::DateHelper
      include ActionView::Helpers::NumberHelper

      GEO_STATUS_COLUMN_WIDTH = 35

      attr_reader :current_node_status, :geo_node

      def initialize(current_node_status, geo_node)
        @current_node_status = current_node_status
        @geo_node = geo_node
      end

      def print_status
        print_current_node_info

        print_gitlab_version
        print_geo_role
        print_node_health_status

        print_repositories_status
        print_verified_repositories
        print_wikis_status
        print_verified_wikis
        print_container_repositories_status
        print_design_repositories_status
        print_replicators_status
        print_repositories_checked_status
        print_replicators_verification_status

        print_sync_settings
        print_db_replication_lag
        print_last_event_id
        print_last_status_report_time

        puts
      end

      def print_replication_verification_status
        print_repositories_status
        print_verified_repositories
        print_wikis_status
        print_verified_wikis
        print_container_repositories_status
        print_design_repositories_status
        print_replicators_status
        print_replicators_verification_status
      end

      def replication_verification_complete?
        checks_status =
          legacy_replication_and_verification_checks_status +
          replication_and_verification_checks_status +
          conditional_replication_and_verification_checks_status

        checks_status.compact.all?(100)
      end

      private

      # rubocop:disable GitlabSecurity/PublicSend
      def legacy_replication_and_verification_checks_status
        replicables = [
          ["repositories", Gitlab::Geo.repository_verification_enabled?],
          ["wikis", Gitlab::Geo.repository_verification_enabled?],
          ["job_artifacts", false],
          ["design_repositories", false]
        ]

        [].tap do |status|
          replicables.each do |replicable_name, verification_enabled|
            next unless current_node_status.public_send("#{replicable_name}_count").to_i > 0

            status.push current_node_status.public_send("#{replicable_name}_synced_in_percentage")

            if verification_enabled
              status.push current_node_status.public_send("#{replicable_name}_verified_in_percentage")
            end
          end
        end
      end
      # rubocop:enable GitlabSecurity/PublicSend

      def replication_and_verification_checks_status
        [].tap do |status|
          Gitlab::Geo.enabled_replicator_classes.each do |replicator_class|
            next unless current_node_status.count_for(replicator_class).to_i > 0

            status.push current_node_status.synced_in_percentage_for(replicator_class)

            if replicator_class.verification_enabled?
              status.push current_node_status.verified_in_percentage_for(replicator_class)
            end
          end
        end
      end

      def conditional_replication_and_verification_checks_status
        [].tap do |status|
          if Gitlab::CurrentSettings.repository_checks_enabled && current_node_status.repositories_count.to_i > 0 && \
              !Gitlab::Geo.secondary?
            status.push current_node_status.repositories_checked_in_percentage
          end

          if ::Geo::ContainerRepositoryRegistry.replication_enabled? && current_node_status.container_repositories_count.to_i > 0
            status.push current_node_status.container_repositories_synced_in_percentage
          end
        end
      end

      def print_current_node_info
        puts
        puts "Name: #{GeoNode.current_node_name}"
        puts "URL: #{GeoNode.current_node_url}"
        puts '-----------------------------------------------------'.color(:yellow)
      end

      def print_gitlab_version
        print 'GitLab Version: '.rjust(GEO_STATUS_COLUMN_WIDTH)
        puts Gitlab::VERSION
      end

      def print_geo_role
        print 'Geo Role: '.rjust(GEO_STATUS_COLUMN_WIDTH)
        role =
          if Gitlab::Geo.primary?
            'Primary'
          else
            Gitlab::Geo.secondary? ? 'Secondary' : 'unknown'.color(:yellow)
          end

        puts role
      end

      def print_node_health_status
        print 'Health Status: '.rjust(GEO_STATUS_COLUMN_WIDTH)

        if current_node_status.healthy?
          puts current_node_status.health_status
        else
          puts current_node_status.health_status.color(:red)
        end

        unless current_node_status.healthy?
          print 'Health Status Summary: '.rjust(GEO_STATUS_COLUMN_WIDTH)
          puts current_node_status.health.color(:red)
        end
      end

      def print_sync_settings
        print 'Sync Settings: '.rjust(GEO_STATUS_COLUMN_WIDTH)
        puts  geo_node.namespaces.any? ? 'Selective' : 'Full'
      end

      def print_db_replication_lag
        print 'Database replication lag: '.rjust(GEO_STATUS_COLUMN_WIDTH)
        puts "#{Gitlab::Geo::HealthCheck.new.db_replication_lag_seconds} seconds"
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def print_last_event_id
        print 'Last event ID seen from primary: '.rjust(GEO_STATUS_COLUMN_WIDTH)
        last_event = ::Geo::EventLog.last

        if last_event
          print last_event&.id
          puts " (#{time_ago_in_words(last_event&.created_at)} ago)"

          print 'Last event ID processed by cursor: '.rjust(GEO_STATUS_COLUMN_WIDTH)
          cursor_last_event_id = ::Geo::EventLogState.last_processed&.event_id

          if cursor_last_event_id
            print cursor_last_event_id
            last_cursor_event_date =
              ::Geo::EventLog.find_by(id: cursor_last_event_id)&.created_at
            print " (#{time_ago_in_words(last_cursor_event_date)} ago)" if last_cursor_event_date
            puts
          else
            puts 'Not applicable.'
          end
        else
          puts 'Not applicable.'
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def print_last_status_report_time
        print 'Last status report was: '.rjust(GEO_STATUS_COLUMN_WIDTH)

        if current_node_status.updated_at
          puts "#{time_ago_in_words(current_node_status.updated_at)} ago"
        else
          # Only primary node can create a status record in the database so if
          # it does not exist we get unsaved record where updated_at is nil
          puts 'Never'
        end
      end

      def print_repositories_status
        print_counts_row(
          description: 'Repositories',
          failed: current_node_status.repositories_failed_count,
          succeeded: current_node_status.repositories_synced_count,
          total: current_node_status.projects_count,
          percentage: current_node_status.repositories_synced_in_percentage
        )
      end

      def print_replicators_status
        Gitlab::Geo.enabled_replicator_classes.each do |replicator_class|
          print_counts_row(
            description: replicator_class.replicable_title_plural.to_s,
            failed: replicator_class.failed_count,
            succeeded: replicator_class.synced_count,
            total: replicator_class.registry_count,
            percentage: current_node_status.synced_in_percentage_for(replicator_class)
          )
        end
      end

      def print_verified_repositories
        if Gitlab::Geo.repository_verification_enabled?
          print_counts_row(
            description: 'Verified Repositories',
            failed: current_node_status.repositories_verification_failed_count,
            succeeded: current_node_status.repositories_verified_count,
            total: current_node_status.projects_count,
            percentage: current_node_status.repositories_verified_in_percentage
          )
        end
      end

      def print_wikis_status
        return if ::Geo::ProjectWikiRepositoryReplicator.enabled?

        print_counts_row(
          description: 'Wikis',
          failed: current_node_status.wikis_failed_count,
          succeeded: current_node_status.wikis_synced_count,
          total: current_node_status.projects_count,
          percentage: current_node_status.wikis_synced_in_percentage
        )
      end

      def print_verified_wikis
        return if ::Geo::ProjectWikiRepositoryReplicator.enabled?

        if Gitlab::Geo.repository_verification_enabled?
          print_counts_row(
            description: 'Verified Wikis',
            failed: current_node_status.wikis_verification_failed_count,
            succeeded: current_node_status.wikis_verified_count,
            total: current_node_status.projects_count,
            percentage: current_node_status.wikis_verified_in_percentage
          )
        end
      end

      def print_container_repositories_status
        if ::Geo::ContainerRepositoryRegistry.replication_enabled?
          print_counts_row(
            description: 'Container repositories',
            failed: current_node_status.container_repositories_failed_count,
            succeeded: current_node_status.container_repositories_synced_count,
            total: current_node_status.container_repositories_count,
            percentage: current_node_status.container_repositories_synced_in_percentage
          )
        end
      end

      def print_design_repositories_status
        print_counts_row(
          description: 'Design repositories',
          failed: current_node_status.design_repositories_failed_count,
          succeeded: current_node_status.design_repositories_synced_count,
          total: current_node_status.design_repositories_count,
          percentage: current_node_status.design_repositories_synced_in_percentage
        )
      end

      def print_repositories_checked_status
        if Gitlab::CurrentSettings.repository_checks_enabled
          print_counts_row(
            description: 'Repositories Checked',
            failed: current_node_status.repositories_checked_failed_count,
            succeeded: current_node_status.repositories_checked_count,
            total: current_node_status.projects_count,
            percentage: current_node_status.repositories_checked_in_percentage
          )
        end
      end

      def print_replicators_verification_status
        verifiable_replicator_classes = Gitlab::Geo.verification_enabled_replicator_classes

        verifiable_replicator_classes.each do |replicator_class|
          print_counts_row(
            description: "#{replicator_class.replicable_title_plural} Verified",
            failed: replicator_class.verification_failed_count,
            succeeded: replicator_class.verified_count,
            total: replicator_class.registry_count,
            percentage: current_node_status.verified_in_percentage_for(replicator_class)
          )
        end
      end

      def print_counts_row(description:, failed:, succeeded:, total:, percentage:)
        print "#{description}: ".rjust(GEO_STATUS_COLUMN_WIDTH)
        print "failed #{failed}".color(:red), ' / ' if failed.present? && failed > 0
        print "succeeded #{succeeded || 0} / total #{total || 0} "
        puts  using_percentage(percentage)
      end

      def using_percentage(value)
        "(#{number_to_percentage(
          value.floor,
          precision: 0,
          strip_insignificant_zeros: true
        )})"
      end
    end
  end
end
