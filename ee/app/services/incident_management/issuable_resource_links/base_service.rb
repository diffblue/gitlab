# frozen_string_literal: true

module IncidentManagement
  module IssuableResourceLinks
    class BaseService
      include Gitlab::Utils::UsageData

      def allowed?
        user&.can?(:admin_issuable_resource_link, incident)
      end

      def success(issuable_resource_link)
        ServiceResponse.success(payload: {
          issuable_resource_link: issuable_resource_link
        })
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def error_no_permissions
        error(_('You have insufficient permissions to manage resource links for this incident'))
      end

      def error_in_save(issuable_resource_link)
        error(issuable_resource_link.errors.full_messages.to_sentence)
      end
    end
  end
end
