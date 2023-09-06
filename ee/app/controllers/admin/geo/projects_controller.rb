# frozen_string_literal: true

module Admin
  module Geo
    class ProjectsController < Admin::Geo::ApplicationController
      before_action :check_license!
      before_action :load_registry, except: [:index]
      before_action :limited_actions_message!
      before_action :load_node_data, only: [:index]

      PROJECTS_LIMIT_COUNT = 10001

      def index
        if Feature.enabled?(:geo_project_repository_replication)
          redirect_to admin_geo_nodes_path unless @current_node
          redirect_to project_repositories_path
        end

        @registries = case params[:sync_status]
                      when 'failed'
                        finder.failed_projects.page(params[:page])
                      when 'pending'
                        finder.pending_projects.page(params[:page])
                      when 'synced'
                        finder.synced_projects.page(params[:page])
                      else
                        finder.all_projects.page(params[:page])
                      end

        @registries = @registries.with_search(params[:name]) if params[:name]

        projects_limit_count = finder.all_projects.limit(PROJECTS_LIMIT_COUNT).count
        @action_buttons = [helpers.resync_all_button(projects_limit_count, PROJECTS_LIMIT_COUNT),
          helpers.reverify_all_button(projects_limit_count, PROJECTS_LIMIT_COUNT)]
      end

      def destroy
        unless @registry.project.nil?
          flash[:alert] = s_('Geo|Could not remove tracking entry for an existing project.')
          return redirect_back_or_default(default: admin_geo_projects_path)
        end

        @registry.destroy

        flash[:toast] =
          format(s_('Geo|Tracking entry for project (%{project_id}) was successfully removed.'),
            project_id: @registry.project_id)
        redirect_back_or_default(default: admin_geo_projects_path)
      end

      def reverify
        @registry.flag_repository_for_reverify!

        flash[:toast] = format(s_('Geo|%{name} is scheduled for re-verify'), name: @registry.project.full_name)
        redirect_back_or_default(default: admin_geo_projects_path)
      end

      def resync
        @registry.flag_repository_for_resync!

        flash[:toast] = format(s_('Geo|%{name} is scheduled for re-sync'), name: @registry.project.full_name)
        redirect_back_or_default(default: admin_geo_projects_path)
      end

      def reverify_all
        ::Geo::Batch::ProjectRegistrySchedulerWorker.perform_async(:reverify_repositories) # rubocop:disable CodeReuse/Worker

        flash[:toast] = s_('Geo|All projects are being scheduled for reverify')
        redirect_back_or_default(default: admin_geo_projects_path)
      end

      def resync_all
        ::Geo::Batch::ProjectRegistrySchedulerWorker.perform_async(:resync_repositories) # rubocop:disable CodeReuse/Worker

        flash[:toast] = s_('Geo|All projects are being scheduled for resync')
        redirect_back_or_default(default: admin_geo_projects_path)
      end

      private

      def project_repositories_path
        "/admin/geo/sites/#{@current_node.id}/replication/project_repositories"
      end

      def load_registry
        @registry = ::Geo::ProjectRegistry.find_by_id(params[:id])
      end

      def finder
        @finder ||= ::Geo::ProjectRegistryStatusFinder.new
      end
    end
  end
end
