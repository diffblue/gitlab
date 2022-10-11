# frozen_string_literal: true

module IncidentManagement
  module IssuableResourceLinks
    class CreateService < IssuableResourceLinks::BaseService
      ZOOM_REGEXP = %r{https://(?:[\w-]+\.)?zoom\.us/(?:s|j|my)/\S+}.freeze
      SLACK_REGEXP = %r{https://[a-zA-Z0-9]+.slack\.com/[a-z][a-zA-Z0-9_]+}.freeze

      def initialize(incident, user, params)
        @incident = incident
        @user = user
        @params = params
      end

      def execute
        return error_no_permissions unless allowed?

        params[:link_text] = params[:link] if params[:link_text].blank?

        params[:link_type] = get_link_type if params[:link_type].blank?

        issuable_resource_link_params = params.merge({ issue: incident })
        issuable_resource_link = IncidentManagement::IssuableResourceLink.new(issuable_resource_link_params)

        if issuable_resource_link.save
          track_usage_event(:incident_management_issuable_resource_link_created, user.id)
          SystemNoteService.issuable_resource_link_added(@incident, @incident.project, @user,
            issuable_resource_link.link_type)
          success(issuable_resource_link)
        else
          error_in_save(issuable_resource_link)
        end
      end

      private

      attr_reader :incident, :user, :params

      def get_link_type
        return :zoom if ZOOM_REGEXP.match?(params[:link])

        return :slack if SLACK_REGEXP.match?(params[:link])

        :general
      end
    end
  end
end
