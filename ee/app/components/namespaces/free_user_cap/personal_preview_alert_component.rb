# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class PersonalPreviewAlertComponent < PreviewAlertComponent
      include Personable

      private

      def alert_attributes
        {
          title: n_(
            'From October 19, 2022, you can have a maximum of %d unique member across all of your personal projects',
            'From October 19, 2022, you can have a maximum of %d unique members across all of your personal projects',
            free_user_limit
          ) % free_user_limit,
          body: _(
            '%{over_limit_message} To view and manage members, check the members page for each project in your ' \
            'namespace. We recommend you %{link_start}move your projects to a group%{link_end} so you can easily ' \
            'manage users and features.'
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
          'You currently have more than %{free_user_limit} member across all your personal projects. From ' \
          'October 19, 2022, the %{free_user_limit} most recently active member will remain active, and the ' \
          'remaining members will have the %{link_start}Over limit status%{link_end} and lose access.',
          'You currently have more than %{free_user_limit} members across all your personal projects. From ' \
          'October 19, 2022, the %{free_user_limit} most recently active members will remain active, and the ' \
          'remaining members will have the %{link_start}Over limit status%{link_end} and lose access.',
          free_user_limit
        ).html_safe % {
          free_user_limit: free_user_limit,
          link_start: over_limit_link_start,
          link_end: link_end
        }
      end
    end
  end
end
