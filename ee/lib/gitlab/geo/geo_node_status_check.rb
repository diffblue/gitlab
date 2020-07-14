# frozen_string_literal: true

require 'action_view/helpers'

module Gitlab
  module Geo
    class GeoNodeStatusCheck
      include ActionView::Helpers::DateHelper
      include ActionView::Helpers::NumberHelper

      GEO_STATUS_COLUMN_WIDTH = 40

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
        print_lfs_objects_status
        print_attachments_status
        print_ci_job_artifacts_status
        print_container_repositories_status
        print_design_repositories_status
        print_repositories_checked_status

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
        print_lfs_objects_status
        print_attachments_status
        print_ci_job_artifacts_status
        print_container_repositories_status
        print_design_repositories_status
        print_repositories_checked_status
      end

      def replication_verification_complete?
        replication_complete? && verification_complete?
      end

      private

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
            puts 'N/A'
          end
        else
          puts 'N/A'
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
        print 'Repositories: '.rjust(GEO_STATUS_COLUMN_WIDTH)

        show_failed_value(current_node_status.repositories_failed_count)

        print "#{current_node_status.repositories_synced_count}/#{current_node_status.projects_count} "
        puts using_percentage(current_node_status.repositories_synced_in_percentage)
      end

      def print_verified_repositories
        if Gitlab::Geo.repository_verification_enabled?
          print 'Verified Repositories: '.rjust(GEO_STATUS_COLUMN_WIDTH)
          show_failed_value(current_node_status.repositories_verification_failed_count)
          print "#{current_node_status.repositories_verified_count}/#{current_node_status.projects_count} "
          puts using_percentage(current_node_status.repositories_verified_in_percentage)
        end
      end

      def print_wikis_status
        print 'Wikis: '.rjust(GEO_STATUS_COLUMN_WIDTH)
        show_failed_value(current_node_status.wikis_failed_count)
        print "#{current_node_status.wikis_synced_count}/#{current_node_status.projects_count} "
        puts using_percentage(current_node_status.wikis_synced_in_percentage)
      end

      def print_verified_wikis
        if Gitlab::Geo.repository_verification_enabled?
          print 'Verified Wikis: '.rjust(GEO_STATUS_COLUMN_WIDTH)
          show_failed_value(current_node_status.wikis_verification_failed_count)
          print "#{current_node_status.wikis_verified_count}/#{current_node_status.projects_count} "
          puts using_percentage(current_node_status.wikis_verified_in_percentage)
        end
      end

      def print_lfs_objects_status
        print 'LFS Objects: '.rjust(GEO_STATUS_COLUMN_WIDTH)
        show_failed_value(current_node_status.lfs_objects_failed_count)
        print "#{current_node_status.lfs_objects_synced_count}/#{current_node_status.lfs_objects_count} "
        puts using_percentage(current_node_status.lfs_objects_synced_in_percentage)
      end

      def print_attachments_status
        print 'Attachments: '.rjust(GEO_STATUS_COLUMN_WIDTH)
        show_failed_value(current_node_status.attachments_failed_count)
        print "#{current_node_status.attachments_synced_count}/#{current_node_status.attachments_count} "
        puts using_percentage(current_node_status.attachments_synced_in_percentage)
      end

      def print_ci_job_artifacts_status
        print 'CI job artifacts: '.rjust(GEO_STATUS_COLUMN_WIDTH)
        show_failed_value(current_node_status.job_artifacts_failed_count)
        print "#{current_node_status.job_artifacts_synced_count}/#{current_node_status.job_artifacts_count} "
        puts using_percentage(current_node_status.job_artifacts_synced_in_percentage)
      end

      def print_container_repositories_status
        if Gitlab.config.geo.registry_replication.enabled
          print 'Container repositories: '.rjust(GEO_STATUS_COLUMN_WIDTH)
          show_failed_value(current_node_status.container_repositories_failed_count)
          print "#{current_node_status.container_repositories_synced_count || 0}/#{current_node_status.container_repositories_count || 0} "
          puts using_percentage(current_node_status.container_repositories_synced_in_percentage)
        end
      end

      def print_design_repositories_status
        print 'Design repositories: '.rjust(GEO_STATUS_COLUMN_WIDTH)
        show_failed_value(current_node_status.design_repositories_failed_count)
        print "#{current_node_status.design_repositories_synced_count || 0}/#{current_node_status.design_repositories_count || 0} "
        puts using_percentage(current_node_status.design_repositories_synced_in_percentage)
      end

      def print_repositories_checked_status
        if Gitlab::CurrentSettings.repository_checks_enabled
          print 'Repositories Checked: '.rjust(GEO_STATUS_COLUMN_WIDTH)
          show_failed_value(current_node_status.repositories_checked_failed_count)
          print "#{current_node_status.repositories_checked_count}/#{current_node_status.projects_count} "
          puts using_percentage(current_node_status.repositories_checked_in_percentage)
        end
      end

      def replication_complete?
        replicables.all? { |failed_count| failed_count == 0 }
      end

      def verification_complete?
        verifiables.all? { |failed_count| failed_count == 0 }
      end

      def replicables
        [
          current_node_status.repositories_failed_count,
          current_node_status.wikis_failed_count,
          current_node_status.lfs_objects_failed_count,
          current_node_status.attachments_failed_count,
          current_node_status.job_artifacts_failed_count,
          current_node_status.design_repositories_failed_count
        ].tap do |r|
          if Gitlab.config.geo.registry_replication.enabled
            r.push current_node_status.container_repositories_failed_count
          end
        end
      end

      def verifiables
        [].tap do |v|
          if Gitlab::Geo.repository_verification_enabled?
            v.push(
              current_node_status.repositories_verification_failed_count,
              current_node_status.wikis_verification_failed_count
            )
          end

          if Gitlab::CurrentSettings.repository_checks_enabled
            v.push current_node_status.repositories_checked_failed_count
          end
        end
      end

      def show_failed_value(value)
        print "#{value}".color(:red) + '/' if value > 0
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
