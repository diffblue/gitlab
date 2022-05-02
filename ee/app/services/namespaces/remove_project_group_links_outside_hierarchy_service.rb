# frozen_string_literal: true

module Namespaces
  class RemoveProjectGroupLinksOutsideHierarchyService
    def initialize(namespace)
      @namespace = namespace
      @removed_link_ids = []
    end

    def execute
      return unless namespace && needs_removal?

      remove_links
      log_event

    rescue StandardError => ex
      log_error(ex)
    end

    private

    attr_reader :namespace, :removed_link_ids

    def needs_removal?
      links_outside_hierarchy.any?
    end

    def remove_links
      links_outside_hierarchy.find_each do |link|
        @removed_link_ids << link.id
        ::Projects::GroupLinks::DestroyService.new(link.project, nil).execute(link)
      end
    end

    def internal_groups
      @internal_groups ||= ::Group.groups_including_descendants_by([namespace])
    end

    def links_outside_hierarchy
      @links_outside_hierarchy ||= ProjectGroupLink.in_project(namespace.all_projects).not_in_group(internal_groups)
    end

    def log_event
      log_params = {
        namespace: namespace.id,
        message: "Removing the ProjectGroupLinks outside the hierarchy with ids: #{removed_link_ids}"
      }

      Gitlab::AppLogger.info(log_params)
    end

    def log_error(ex)
      log_params = {
        namespace: namespace.id,
        message: 'An error has occurred',
        details: ex.message
      }

      Gitlab::AppLogger.error(log_params)
    end
  end
end
