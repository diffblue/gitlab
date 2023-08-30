# frozen_string_literal: true

# Security::VulnerabilitiesFinder
#
# Used to filter Vulnerability records for Vulnerabilities API
#
# Arguments:
#   vulnerable: any object that has a #vulnerabilities method that returns a collection of `Vulnerability`s
#   params: optional! a hash with one or more of the following:
#     project_ids: if `vulnerable` includes multiple projects (like a Group), this filter will restrict
#                   the vulnerabilities returned to those in the group's projects that also match these IDs
#     include_archived_projects: defaulted to `false`. Determines if results will include vulnerabilities
#                                 associated with archived projects
#     image: only return vulnerabilities with these location images
#     report_types: only return vulnerabilities from these report types
#     severities: only return vulnerabilities with these severities
#     states: only return vulnerabilities in these states
#     has_resolution: only return vulnerabilities that have resolution
#     has_issues: only return vulnerabilities that have issues linked
#     sort: return vulnerabilities ordered by severity_asc or severity_desc

module Security
  class VulnerabilitiesFinder
    include FinderMethods

    def initialize(vulnerable, params = {})
      @params = { include_archived_projects: false }.merge(params)
      @vulnerable = vulnerable
      @vulnerabilities = vulnerable.vulnerabilities
    end

    def execute
      # As we are creating vulnerability with default branch set to false irrespective of feature flag
      # from user interaction (issue/mr creation and dismissal of finding), we always need to do this filtering
      filter_by_present_on_default_branch
      filter_archived_projects
      filter_by_projects
      filter_by_image
      filter_by_report_types
      filter_by_severities
      filter_by_states
      filter_by_scanner_external_id
      filter_by_scanner_ids
      filter_by_resolution
      filter_by_issues
      filter_by_cluster_id
      filter_by_cluster_agent_id

      sort(vulnerabilities)
    end

    private

    attr_reader :params, :vulnerable, :vulnerabilities

    def filter_by_present_on_default_branch
      @vulnerabilities = if params[:present_on_default_branch].eql?(false)
                           vulnerabilities
                         else
                           vulnerabilities.for_default_branch
                         end
    end

    def filter_archived_projects
      return if params[:include_archived_projects] == true
      return unless vulnerable.is_a?(Group)

      # `filter_by_projects` will handle archived projects
      return if params[:project_id].present?

      @vulnerabilities = vulnerabilities.without_archived_projects
    end

    def filter_by_projects
      if params[:project_id].present?
        @vulnerabilities = vulnerabilities.for_projects(
          params[:project_id],
          params[:include_archived_projects]
        )
      end
    end

    def filter_by_report_types
      if params[:report_type].present?
        @vulnerabilities = vulnerabilities.with_report_types(params[:report_type])
      end
    end

    def filter_by_severities
      if params[:severity].present?
        @vulnerabilities = vulnerabilities.with_severities(params[:severity])
      end
    end

    def filter_by_states
      if params[:state].present?
        @vulnerabilities = vulnerabilities.with_states(params[:state])
      end
    end

    def filter_by_scanner_ids
      if params[:scanner_id].present?
        @vulnerabilities = vulnerabilities.by_scanner_ids(params[:scanner_id])
      end
    end

    def filter_by_scanner_external_id
      if params[:scanner].present?
        @vulnerabilities = vulnerabilities.with_scanner_external_ids(params[:scanner])
      end
    end

    def filter_by_resolution
      if params[:has_resolution].in?([true, false])
        @vulnerabilities = vulnerabilities.with_resolution(params[:has_resolution])
      end
    end

    def filter_by_issues
      if params[:has_issues].in?([true, false])
        @vulnerabilities = vulnerabilities.with_issues(params[:has_issues])
      end
    end

    def filter_by_image
      # This filter will not work for InstanceSecurityDashboard, because InstanceSecurityDashboard could have multiple projects.
      return if vulnerable.is_a?(InstanceSecurityDashboard)

      if params[:image].present?
        @vulnerabilities = vulnerabilities.with_container_image(params[:image])
      end
    end

    def filter_by_cluster_id
      if params[:cluster_id].present?
        @vulnerabilities = vulnerabilities.with_cluster_ids(params[:cluster_id])
      end
    end

    def filter_by_cluster_agent_id
      if params[:cluster_agent_id].present?
        @vulnerabilities = vulnerabilities.with_cluster_agent_ids(params[:cluster_agent_id])
      end
    end

    def sort(items)
      items.order_by(params[:sort])
    end
  end
end
