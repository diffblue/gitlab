# frozen_string_literal: true

module Projects
  module Integrations
    module Jira
      class IssuesController < Projects::ApplicationController
        include RecordUserLastActivity
        include SortingHelper
        include SortingPreference
        include ProductAnalyticsTracking

        track_event :index,
          name: 'i_ecosystem_jira_service_list_issues',
          action: Integration::SNOWPLOW_EVENT_ACTION,
          label: Integration::SNOWPLOW_EVENT_LABEL,
          destinations: %i(redis_hll snowplow)

        before_action :check_feature_enabled!

        rescue_from ::Projects::Integrations::Jira::IssuesFinder::Error, with: :render_error

        feature_category :integrations

        def index
          params[:state] = params[:state].presence || default_state

          respond_to do |format|
            format.html
            format.json do
              render json: issues_json
            end
          end
        end

        def show
          return render_404 if issue_json.nil?

          respond_to do |format|
            format.html do
              issue_json
            end
            format.json do
              render json: issue_json
            end
          end
        end

        private

        def visitor_id
          current_user&.id
        end

        def issues_json
          jira_issues = Kaminari.paginate_array(
            finder.execute,
            limit: finder.per_page,
            total_count: finder.total_count
          )

          ::Integrations::JiraSerializers::IssueSerializer.new
            .with_pagination(request, response)
            .represent(jira_issues, project: project)
        end

        def issue_json
          @issue_json ||= ::Integrations::JiraSerializers::IssueDetailSerializer.new
            .represent(
              project.jira_integration.find_issue(
                params[:id],
                rendered_fields: true,
                restrict_project_key: true
              ),
              current_user: current_user,
              project: project
            )
        end

        def finder
          @finder ||= ::Projects::Integrations::Jira::IssuesFinder.new(project, finder_options)
        end

        def finder_options
          options = { sort: set_sort_order }

          # Used by view to highlight active option
          @sort = options[:sort]

          params.permit(::Projects::Integrations::Jira::IssuesFinder.valid_params).merge(options)
        end

        def default_state
          'opened'
        end

        def default_sort_order
          case params[:state]
          when 'opened', 'all' then sort_value_created_date
          when 'closed'        then sort_value_recently_updated
          else sort_value_created_date
          end
        end

        protected

        def check_feature_enabled!
          return render_404 unless project.jira_issues_integration_available? &&
                                    jira_integration&.active &&
                                    jira_integration&.issues_enabled
        end

        def jira_integration
          @jira_integration ||= project.jira_integration
        end

        def render_error(exception)
          log_exception(exception)

          render json: { errors: [exception.message] }, status: :bad_request
        end

        def tracking_namespace_source
          project.namespace
        end

        def tracking_project_source
          project
        end
      end
    end
  end
end
