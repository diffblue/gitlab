# frozen_string_literal: true

module Namespaces
  module Storage
    class LimitAlertComponent < ViewComponent::Base
      # @param [Namespace or Group] namespace
      # @param [User] user
      # @param [EE::Namespace::Storage::Notification] notification
      def initialize(context:, user:, notification_data:)
        @root_namespace = context.root_ancestor
        @user = user
        @notification_data = notification_data
      end

      private

      delegate :sprite_icon, :usage_quotas_path, :buy_storage_path, :purchase_storage_url, to: :helpers
      attr_reader :root_namespace, :user, :notification_data

      def render?
        !dismissed?
      end

      def alert_variant
        if notification_data[:alert_level] == :error || notification_data[:alert_level] == :alert
          return :danger
        end

        notification_data[:alert_level]
      end

      def alert_icon
        alert_level = notification_data[:alert_level]

        if alert_level == :error || alert_level == :alert
          'error'
        else
          alert_level == :info ? 'information-o' : alert_level.to_s
        end
      end

      def alert_title
        notification_data[:usage_message]
      end

      def alert_message
        notification_data[:explanation_message]
      end

      def alert_body_message
        alert_message.dig(:main, :text)
      end

      def alert_body_cta_text
        alert_message.dig(:main, :link, :text)
      end

      def alert_body_cta_href
        alert_message.dig(:main, :link, :href)
      end

      def alert_footer_message
        return unless notification_data[:enforcement_type] == :namespace

        alert_message.dig(:footer, :text)
      end

      def alert_footer_cta_text
        alert_message.dig(:footer, :link, :text)
      end

      def alert_footer_cta_href
        alert_message.dig(:footer, :link, :href)
      end

      def alert_callout_path
        root_namespace.user_namespace? ? callouts_path : group_callouts_path
      end

      def root_namespace_id
        root_namespace.id
      end

      def callout_feature_name
        "namespace_storage_limit_banner_#{notification_data[:alert_level]}_threshold"
      end

      def purchase_link
        return unless show_purchase_link?

        buy_storage_path(root_namespace)
      end

      def show_purchase_link?
        return false unless ::Gitlab::CurrentSettings.automatic_purchased_storage_allocation?

        Ability.allowed?(user, :owner_access, root_namespace)
      end

      def usage_quotas_link
        usage_quotas_path(root_namespace, anchor: 'storage-quota-tab')
      end

      def dismissed?
        if root_namespace.user_namespace?
          user.dismissed_callout?(feature_name: callout_feature_name)
        else
          user.dismissed_callout_for_group?(
            feature_name: callout_feature_name,
            group: root_namespace
          )
        end
      end

      def content_class
        "container-limited limit-container-width" unless user.layout == "fluid"
      end
    end
  end
end
