# frozen_string_literal: true

module IncidentManagement
  module IssuableResourceLinks
    class DestroyService < IssuableResourceLinks::BaseService
      def initialize(issuable_resource_link, user)
        @issuable_resource_link = issuable_resource_link
        @user = user
        @incident = issuable_resource_link.issue
      end

      def execute
        return error_no_permissions unless allowed?

        if issuable_resource_link.destroy
          success(issuable_resource_link)
        else
          error_in_save(issuable_resource_link)
        end
      end

      private

      attr_reader :issuable_resource_link, :user, :incident
    end
  end
end
