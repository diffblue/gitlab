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
#     report_types: only return vulnerabilities from these report types
#     severities: only return vulnerabilities with these severities
#     states: only return vulnerabilities in these states
#     sort: return vulnerabilities ordered by severity_asc or severity_desc

module Security
  class VulnerabilitiesFinder
    include FinderMethods

    def initialize(vulnerable, params = {})
      @params = params
      @vulnerabilities = vulnerable.vulnerabilities
    end

    def execute
      filter_by_projects
      filter_by_report_types
      filter_by_severities
      filter_by_states
      filter_by_scanners

      sort(vulnerabilities)
    end

    private

    attr_reader :params, :vulnerabilities

    def filter_by_projects
      if params[:project_id].present?
        @vulnerabilities = vulnerabilities.for_projects(params[:project_id])
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

    def filter_by_scanners
      if params[:scanner].present?
        @vulnerabilities = vulnerabilities.with_scanners(params[:scanner])
      end
    end

    def sort(items)
      items.order_by(params[:sort])
    end
  end
end
