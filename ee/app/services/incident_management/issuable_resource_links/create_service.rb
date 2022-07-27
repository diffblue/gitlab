# frozen_string_literal: true

module IncidentManagement
  module IssuableResourceLinks
    class CreateService < IssuableResourceLinks::BaseService
      def initialize(incident, user, params)
        @incident = incident
        @user = user
        @params = params
      end

      def execute
        return error_no_permissions unless allowed?

        params[:link_text] = params[:link] if params[:link_text].nil?

        issuable_resource_link_params = params.merge({ issue: incident })
        issuable_resource_link = IncidentManagement::IssuableResourceLink.new(issuable_resource_link_params)

        if issuable_resource_link.save
          success(issuable_resource_link)
        else
          error_in_save(issuable_resource_link)
        end
      end

      private

      attr_reader :incident, :user, :params
    end
  end
end
