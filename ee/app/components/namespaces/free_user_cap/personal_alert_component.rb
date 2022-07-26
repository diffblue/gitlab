# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class PersonalAlertComponent < AlertComponent
      include Personable

      def alert_attributes
        {
          title: _("You've reached your %{free_limit} member limit across all of your personal projects") % {
            free_limit: free_user_limit
          },
          body: _(
            '%{over_limit_message} To view and manage members, check the members page for each personal project. ' \
            'We recommend you %{link_start}move your projects to a group%{link_end} so you can easily manage users ' \
            'and features.'
          ).html_safe % {
            over_limit_message: over_limit_message,
            link_start: move_link_start,
            link_end: link_end
          },
          primary_cta: personal_primary_cta
        }
      end

      def over_limit_message
        n_(
          'You can have a maximum of %{free_user_limit} unique member across all of your personal projects.',
          'You can have a maximum of %{free_user_limit} unique members across all of your personal projects.',
          free_user_limit
        ).html_safe % { free_user_limit: free_user_limit }
      end
    end
  end
end
