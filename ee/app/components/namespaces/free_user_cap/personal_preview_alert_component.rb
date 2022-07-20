# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class PersonalPreviewAlertComponent < PreviewAlertComponent
      include Personable

      private

      def alert_attributes
        {
          title: _('From October 19, 2022, you can have a maximum of %{free_limit} unique members ' \
                 'across all of your personal projects') % { free_limit: ::Namespaces::FreeUserCap::FREE_USER_LIMIT },
          body: _('You currently have more than %{free_limit} members across all your personal projects. ' \
                'From October 19, 2022, the %{free_limit} most recently active members will remain active, ' \
                'and the remaining members will get a %{link_start}status of Over limit%{link_end} and lose access. ' \
                'To view and manage members, check the members page for each project in your namespace. ' \
                'We recommend you %{move_link_start}move your project to a group%{move_link_end} so you can easily ' \
                'manage users and features.').html_safe % {
            free_limit: ::Namespaces::FreeUserCap::FREE_USER_LIMIT,
            link_start: '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: BLOG_URL },
            link_end: link_end,
            move_link_start: move_link_start,
            move_link_end: link_end
          },
          primary_cta: personal_primary_cta
        }
      end
    end
  end
end
