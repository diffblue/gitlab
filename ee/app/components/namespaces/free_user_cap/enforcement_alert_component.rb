# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    class EnforcementAlertComponent < BaseAlertComponent
      private

      PROMOTION_URL = 'https://about.gitlab.com/pricing/faq-efficient-free-tier/#transition-offer'
      OFFER_AVAILABILITY_URL = 'https://about.gitlab.com/pricing/faq-efficient-free-tier/#q-is-this-offer-available-for-all-free-tier-users'

      def variant
        :danger
      end

      def dismissible
        false
      end

      def dismissed?
        false
      end

      def alert_attributes
        {
          title: alert_title,
          body: _("To remove the %{link_start}read-only%{link_end} state and regain write access, " \
                  "you can reduce the number of users in your top-level group to %{free_limit} users or " \
                  "less. You can also upgrade to a paid tier, which do not have user limits. If you " \
                  "need additional time, you can start a free 30-day trial which includes unlimited " \
                  "users. To minimize the impact to operations, for a limited time, GitLab is " \
                  "offering a %{promotion_link_start}one-time 70 percent discount%{link_end} " \
                  "off the list price at time of purchase for a new, one year subscription of " \
                  "GitLab Premium SaaS to %{offer_availability_link_start}qualifying top-level groups%{link_end}. " \
                  "The offer is valid until %{offer_date}.").html_safe % {
            link_start: free_user_limit_link_start,
            promotion_link_start: promotion_link_start_short,
            offer_availability_link_start: offer_availability_link_start_short,
            offer_date: l(Date.new(2023, 8, 13), format: :long),
            link_end: link_end,
            free_limit: free_user_limit
          },
          primary_cta: namespace_primary_cta,
          secondary_cta: namespace_secondary_cta
        }
      end

      def alert_title
        _("Your top-level group %{namespace_name} is over the %{free_limit} user " \
          'limit and has been placed in a read-only state.').html_safe % {
          free_limit: free_user_limit,
          namespace_name: namespace.name
        }
      end

      def free_user_limit_link_start
        "<a href='#{free_user_limit_url}' target='_blank' rel='noopener noreferrer'>".html_safe
      end

      def free_user_limit_url
        help_page_path('user/free_user_limit')
      end

      def promotion_link_start_short
        "<a href='#{PROMOTION_URL}' target='_blank' rel='noopener noreferrer'>".html_safe
      end

      def offer_availability_link_start_short
        "<a href='#{OFFER_AVAILABILITY_URL}' target='_blank' rel='noopener noreferrer'>".html_safe
      end
    end
  end
end
