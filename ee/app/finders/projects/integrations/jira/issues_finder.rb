# frozen_string_literal: true

module Projects
  module Integrations
    module Jira
      class IssuesFinder
        Error = Class.new(StandardError)
        IntegrationError = Class.new(Error)
        RequestError = Class.new(Error)

        attr_reader :issues, :total_count, :per_page

        class << self
          def valid_params
            @valid_params ||= %i[page per_page search state status author_username assignee_username]
            # to permit array params you need to init them to an empty array
            @valid_params << { labels: [], vulnerability_ids: [], issue_ids: [] }
          end
        end

        def initialize(project, params = {})
          @project = project
          @jira_integration = project.jira_integration
          @params = params.merge(map_sort_values(params[:sort]))
          set_pagination
        end

        def execute
          return [] unless project.jira_issues_integration_available?

          raise IntegrationError, _('Jira service not configured.') unless jira_integration&.active?

          project_key = jira_integration.project_key
          raise IntegrationError, _('Jira project key is not configured.') if project_key.blank?

          fetch_issues(project_key)
        end

        private

        attr_reader :project, :jira_integration, :page, :params

        # rubocop: disable CodeReuse/ServiceClass
        def fetch_issues(project_key)
          jql = ::Jira::JqlBuilderService.new(project_key, params).execute
          response = ::Jira::Requests::Issues::ListService
                       .new(jira_integration, { jql: jql, page: page, per_page: per_page })
                       .execute

          raise RequestError, response.message if response.error?

          @total_count = response.payload[:total_count]
          @issues = response.payload[:issues]
        end
        # rubocop: enable CodeReuse/ServiceClass

        def map_sort_values(sort)
          case sort
          when 'created_date', 'created_desc'
            { sort: 'created', sort_direction: 'DESC' }
          when 'created_asc'
            { sort: 'created', sort_direction: 'ASC' }
          when 'updated_desc'
            { sort: 'updated', sort_direction: 'DESC' }
          when 'updated_asc'
            { sort: 'updated', sort_direction: 'ASC' }
          else
            { sort: ::Jira::JqlBuilderService::DEFAULT_SORT, sort_direction: ::Jira::JqlBuilderService::DEFAULT_SORT_DIRECTION }
          end
        end

        def set_pagination
          @page = (params[:page].presence || 1).to_i
          @per_page = (params[:per_page].presence || ::Jira::Requests::Issues::ListService::PER_PAGE).to_i
        end
      end
    end
  end
end
