# frozen_string_literal: true

module IncidentManagement
  module IssuableResourceLinks
    class ZoomLinkService < IssuableResourceLinks::BaseService
      def initialize(project:, current_user:, incident:)
        @incident = incident
        @user = current_user
        @project = project
      end

      def add_link(link, link_text)
        if can_add_link? && (link = parse_link_param(link))
          add_zoom_meeting(link, link_text)
        else
          error(_('Failed to add a Zoom meeting'))
        end
      end

      def can_add_link?
        allowed?
      end

      def parse_link(link_params)
        return unless link_params

        link_params = link_params.split(' ', 2)
        link = parse_link_param(link_params[0])

        return unless link

        link_text = link_params[1]&.strip
        [link, link_text.presence]
      end

      def can_remove_link?
        false
      end

      private

      attr_reader :incident, :user, :project

      def track_meeting_added_event
        ::Gitlab::Tracking.event('IncidentManagement::ZoomIntegration',
          'add_zoom_meeting',
          label: 'Issue ID', value: incident.id,
          user: user, project: @project, namespace: @project.namespace)
      end

      def add_zoom_meeting(link, link_text)
        zoom_meeting = new_zoom_meeting(link, link_text).execute
        if zoom_meeting.success?
          track_meeting_added_event
          success(
            message: _('Zoom meeting added'),
            payload: {
              zoom_meetings: [zoom_meeting.payload[:issuable_resource_link]]
            }
          )
        else
          error(_('Failed to add a Zoom meeting'))
        end
      end

      def new_zoom_meeting(link, link_text)
        IssuableResourceLinks::CreateService.new(@incident,
          user, { link: link, link_text: link_text, link_type: :zoom })
      end

      def success(message:, payload: nil)
        ServiceResponse.success(message: message, payload: payload)
      end

      def parse_link_param(link)
        ::Gitlab::ZoomLinkExtractor.new(link).links.last
      end
    end
  end
end
