# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    module Personable
      extend ActiveSupport::Concern

      private

      def dismissed?
        user.dismissed_callout?(feature_name: feature_name,
                                ignore_dismissal_earlier_than: ignore_dismissal_earlier_than)
      end

      def alert_data
        base_alert_data.merge(dismiss_endpoint: callouts_path)
      end

      def personal_primary_cta
        link_to _('View all personal projects'),
                user_projects_path(user.username),
                class: 'btn gl-alert-action btn-info btn-md gl-button',
                data: {
                  track_action: 'click_button',
                  track_label: 'view_personal_projects',
                  testid: 'user-over-limit-primary-cta'
                }
      end

      def move_link_start
        '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: move_url }
      end

      def move_url
        help_page_path('tutorials/move_personal_project_to_a_group')
      end
    end
  end
end
