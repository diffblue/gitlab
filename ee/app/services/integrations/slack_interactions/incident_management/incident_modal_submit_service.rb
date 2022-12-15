# frozen_string_literal: true

module Integrations
  module SlackInteractions
    module IncidentManagement
      class IncidentModalSubmitService
        include GitlabRoutingHelper
        include Gitlab::Routing

        IssueCreateError = Class.new(StandardError)

        def initialize(params)
          @params = params
          @values = params.dig(:view, :state, :values)
          @team_id = params.dig(:team, :id)
          @user_id = params.dig(:user, :id)
        end

        attr_accessor :params, :values, :team_id, :user_id

        def execute
          create_response = Issues::CreateService.new(
            project: project,
            current_user: find_user.user,
            params: incident_params,
            spam_params: nil
          ).execute

          raise IssueCreateError, create_response.errors.to_sentence if create_response.error?

          incident = create_response.payload[:issue]
          incident_link = incident_link_text(incident)
          response = send_to_slack(incident_link)

          return ServiceResponse.success(payload: { incident: incident }) if response['ok']

          ServiceResponse.error(
            message: _('Something went wrong when sending the incident link to Slack.'),
            payload: response
          ).track_exception(
            response: response.to_h,
            slack_workspace_id: team_id,
            slack_user_id: user_id
          )
        rescue StandardError => e
          send_to_slack(_('There was a problem creating the incident. Please try again.'))

          ServiceResponse
            .error(
              message: e.message
            ).track_exception(
              slack_workspace_id: team_id,
              slack_user_id: user_id,
              as: e.class
            )
        end

        private

        def incident_params
          {
            "title": values.dig(:title_input, :title, :value),
            "severity": severity,
            "confidential": confidential?,
            "description": description,
            "escalation_status": { status: status },
            "issue_type": "incident"
          }
        end

        def send_to_slack(text)
          response_url = params.dig(:view, :private_metadata)

          body = {
            'replace_original': 'true',
            'text': text
          }

          Gitlab::HTTP.post(
            response_url,
            body: Gitlab::Json.dump(body),
            headers: { 'Content-Type' => 'application/json' }
          )
        end

        def incident_link_text(incident)
          "#{_('New incident has been created')}: <#{issue_url(incident)}|#{incident.to_reference} - #{incident.title}>"
        end

        def project
          project_id = values.dig(:project_and_severity_selector, :project, :selected_option, :value)

          Project.find(project_id)
        end

        def find_user
          ChatNames::FindUserService.new(team_id, user_id).execute
        end

        def description
          description = values.dig(:incident_description, :description, :value)
          zoom_link = values.dig(:zoom, :link, :value)

          return description if zoom_link.blank?

          "#{description} \n/zoom #{zoom_link}"
        end

        def confidential?
          values.dig(:confidentiality, :confidential, :selected_options).present?
        end

        def severity
          values.dig(:project_and_severity_selector, :severity, :selected_option, :value) || 'unknown'
        end

        def status
          values.dig(:status_and_assignee_selector, :status, :selected_option, :value)
        end
      end
    end
  end
end
