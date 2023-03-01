# frozen_string_literal: true

module EE
  module WebHooks
    module WebHooksHelper
      def show_group_hook_failed_callout?(group:)
        return false if group_hook_page?

        show_hook_failed_callout?(group)
      end

      def group_hook_page?
        current_controller?('groups/hooks') || current_controller?('groups/hook_logs')
      end

      private

      def can_access_web_hooks?(object)
        return super if object.is_a?(Project)

        Ability.allowed?(current_user, :admin_group, object)
      end
    end
  end
end
