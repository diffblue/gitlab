# frozen_string_literal: true

module StatusPage
  # Publishes content to status page by delegating to specific
  # publishing services.
  #
  # Use this service for publishing an incident to CDN synchronously.
  # To publish asynchronously use +StatusPage::TriggerPublishService+ instead.
  # Called within an async job so as to run out of out of band from web requests
  #
  # This services calls:
  # * StatusPage::PublishDetailsService
  # * StatusPage::UnpublishDetailsService
  # * StatusPage::PublishListService
  class PublishService
    include Gitlab::Utils::StrongMemoize
    include Gitlab::Utils::UsageData

    def initialize(user:, project:, issue_id:)
      @user = user
      @project = project
      @issue_id = issue_id
    end

    def execute
      return error_permission_denied unless can_publish?
      return error_issue_not_found unless issue

      response = process_details
      return response if response.error?

      track_event

      process_list
    end

    private

    attr_reader :user, :project, :issue_id

    def process_details
      should_unpublish? ? unpublish_details : publish_details
    end

    def should_unpublish?
      strong_memoize(:should_unpublish) do
        issue.confidential? || !issue.status_page_published_incident
      end
    end

    def process_list
      PublishListService.new(project: project).execute(issues)
    end

    def publish_details
      PublishDetailsService.new(project: project).execute(issue, user_notes)
    end

    def unpublish_details
      UnpublishDetailsService.new(project: project).execute(issue)
    end

    def issue
      strong_memoize(:issue) { issues_finder.find_by_id(issue_id) }
    end

    def user_notes
      strong_memoize(:user_notes) do
        IncidentCommentsFinder.new(issue: issue).all
      end
    end

    def issues
      strong_memoize(:issues) { issues_finder.all }
    end

    def issues_finder
      strong_memoize(:issues_finder) do
        IncidentsFinder.new(project_id: project.id)
      end
    end

    def can_publish?
      user.can?(:publish_status_page, project)
    end

    def error_permission_denied
      error('No publish permission')
    end

    def error_issue_not_found
      error('Issue not found')
    end

    def error(message)
      ServiceResponse.error(message: message)
    end

    def track_event
      return if should_unpublish?

      namespace = project.namespace
      event = 'incident_management_incident_published'

      return unless Feature.enabled?(:usage_data_incident_management_incident_published, namespace)

      track_usage_event(event, user.id)

      Gitlab::Tracking.event(
        self.class.to_s,
        event,
        project: project,
        namespace: namespace,
        user: user,
        label: 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly',
        context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: event).to_context]
      )
    end
  end
end
