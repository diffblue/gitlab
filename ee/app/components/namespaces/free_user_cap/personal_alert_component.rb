# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class PersonalAlertComponent < AlertComponent
      include Personable

      def alert_attributes
        {
          title: _("You've reached your %{free_limit} member limit across all of your personal projects") % {
            free_limit: ::Namespaces::FreeUserCap::FREE_USER_LIMIT
          },
          body: _('You can have a maximum of %{free_limit} unique members across all of your personal projects. ' \
                'To view and manage members, check the members page for each project in your namespace. ' \
                'We recommend you %{move_link_start}move your projects to a group%{move_link_end} so you can ' \
                'easily manage users and features.').html_safe % {
            free_limit: ::Namespaces::FreeUserCap::FREE_USER_LIMIT,
            move_link_start: move_link_start,
            move_link_end: link_end
          },
          primary_cta: personal_primary_cta
        }
      end
    end
  end
end
