# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class NotificationAlertComponent < BaseAlertComponent
      private

      PROMOTION_URL = 'https://about.gitlab.com/pricing/faq-efficient-free-tier/#transition-offer'

      def breached_cap_limit?
        ::Namespaces::FreeUserCap::Notification.new(namespace).over_limit?
      end

      def dismissible
        false
      end

      def dismissed?
        false
      end

      def alert_attributes
        {
          title: Kernel.format(
            _(
              'Your top-level group %{namespace_name} will move to a read-only state soon'
            ),
            namespace_name: namespace.name
          ).html_safe,
          body: Kernel.format(
            _(
              'Because you are over the %{free_user_limit} user limit, ' \
              'your top-level group, including any subgroups and projects, will be placed in a ' \
              '%{readonly_link_start}read-only state%{link_end} soon. To retain write access, ' \
              'reduce the number of users of your top-level group to ' \
              '%{free_user_limit} or less, or purchase a paid tier. To minimize the impact to your operations, ' \
              'GitLab is offering a %{promotion_link_start}one-time discount%{link_end} ' \
              'for a new purchase of a one-year subscription of GitLab Premium SaaS.'
            ),
            free_user_limit: free_user_limit,
            readonly_link_start: read_only_namespaces_link_start,
            promotion_link_start: "<a href='#{PROMOTION_URL}' target='_blank' rel='noopener noreferrer'>".html_safe,
            link_end: link_end
          ).html_safe,
          primary_cta: namespace_primary_cta,
          secondary_cta: namespace_secondary_cta
        }
      end

      def read_only_namespaces_link_start
        "<a href='#{help_page_path('user/read_only_namespaces')}' target='_blank' rel='noopener noreferrer'>".html_safe
      end
    end
  end
end
