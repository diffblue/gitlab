# frozen_string_literal: true

module Namespaces
  module CombinedStorageUsers
    class BaseAlertComponent < ViewComponent::Base
      include SafeFormatHelper
      include ::Namespaces::CombinedStorageUsers::PreEnforcement

      # @param [Namespace or Group] root_namespace
      # @param [User] user
      # @param [String] content_class
      def initialize(root_namespace:, user:, content_class:)
        @root_namespace = root_namespace
        @user = user
        @content_class = content_class
      end

      private

      attr_reader :root_namespace, :user, :content_class

      def render?
        return false unless over_both_limits?(root_namespace)

        !dismissed?
      end

      def variant
        :warning
      end

      def feature_name
        'namespace_over_storage_users_combined_alert'
      end

      def dismissible
        true
      end

      def dismissed?
        user.dismissed_callout_for_group?(
          feature_name: feature_name,
          group: root_namespace,
          ignore_dismissal_earlier_than: 14.days.ago
        )
      end

      def alert_title
        safe_format(_("Free top-level groups will soon be limited to %{free_users_limit} users " \
                      "and %{free_storage_limit} of data"), alert_title_params)
      end

      def alert_options_data
        {
          track_action: 'render',
          track_label: 'storage_users_limit_banner',
          feature_id: feature_name,
          dismiss_endpoint: group_callouts_path,
          group_id: root_namespace.id
        }
      end

      def close_button_options_data
        {
          track_action: 'dismiss_banner',
          track_label: 'storage_users_limit_banner'
        }
      end

      def container_class
        "gl-overflow-auto #{content_class}"
      end

      def alert_title_params
        { free_users_limit: free_users_limit, free_storage_limit: free_storage_limit }
      end

      def alert_body_params
        {
          group_name: root_namespace.name,
          read_only_link_start: read_only_link_start,
          faq_link_start: faq_link_start,
          promotion_link_start: promotion_link_start,
          offer_availability_link_start: offer_availability_link_start,
          link_end: link_end,
          free_users_limit: free_users_limit,
          free_storage_limit: free_storage_limit,
          strong_start: strong_start,
          strong_end: strong_end,
          br_tag: br_tag
        }
      end

      def free_users_limit
        ::Namespaces::FreeUserCap.dashboard_limit
      end

      def free_storage_limit
        limit = root_namespace.actual_limits.storage_size_limit.megabytes
        number_to_human_size(limit, precision: 0)
      end

      def read_only_link_start
        link_start(help_page_path('user/read_only_namespaces'))
      end

      def faq_link_start
        link_start('https://about.gitlab.com/pricing/faq-efficient-free-tier/#next-steps')
      end

      def promotion_link_start
        link_start("https://about.gitlab.com/pricing/faq-efficient-free-tier/#transition-offer")
      end

      def offer_availability_link_start
        link_start("https://about.gitlab.com/pricing/faq-efficient-free-tier/#q-is-this-offer-available-for-all-free-tier-users")
      end

      def link_start(url)
        "<a href='#{url}' target='_blank' rel='noopener noreferrer'>".html_safe
      end

      def link_end
        '</a>'.html_safe
      end

      def strong_start
        '<strong>'.html_safe
      end

      def strong_end
        '</strong>'.html_safe
      end

      def br_tag
        '<br />'.html_safe
      end
    end
  end
end
