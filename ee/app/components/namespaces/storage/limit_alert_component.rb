# frozen_string_literal: true

module Namespaces
  module Storage
    class LimitAlertComponent < ViewComponent::Base
      # @param [Namespace, Group or Project] context
      # @param [User] user
      def initialize(context:, user:)
        @context = context
        @root_namespace = context.root_ancestor
        @user = user
        @root_storage_size = root_namespace.root_storage_size
      end

      private

      delegate :sprite_icon, :usage_quotas_path, :buy_storage_path,
        :purchase_storage_url, :promo_url, :link_button_to,
        to: :helpers
      attr_reader :context, :root_namespace, :user, :root_storage_size

      def render?
        return false unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
        return false unless user.present?
        return false unless user_has_access?
        return false unless root_storage_size.enforce_limit?
        return false if alert_level == :none

        !user_has_dismissed_alert?
      end

      def alert_title
        return usage_percentage_alert_title unless root_storage_size.above_size_limit?

        if namespace_has_additional_storage_purchased?
          usage_percentage_alert_title
        else
          free_tier_alert_title
        end
      end

      def alert_message
        [
          alert_message_explanation << " " << alert_message_cta,
          alert_message_faq
        ]
      end

      def alert_variant
        return :danger if attention_required_alert_level?

        alert_level
      end

      def alert_icon
        attention_required_alert_level? ? 'error' : alert_level.to_s
      end

      def alert_callout_path
        root_namespace.user_namespace? ? callouts_path : group_callouts_path
      end

      def root_namespace_id
        root_namespace.id
      end

      def callout_feature_name
        "#{root_storage_size.enforcement_type}_alert_#{alert_level}_threshold"
      end

      def purchase_link
        return unless show_purchase_link?

        buy_storage_path(root_namespace)
      end

      def usage_quotas_link
        return unless Ability.allowed?(user, :owner_access, root_namespace)

        usage_quotas_path(root_namespace, anchor: 'storage-quota-tab')
      end

      def content_class
        "container-limited limit-container-width" unless user.layout == "fluid"
      end

      def dismissible?
        !attention_required_alert_level?
      end

      def attention_required_alert_level?
        [:alert, :error].include?(alert_level)
      end

      def alert_level
        usage_thresholds = {
          none: 0.0,
          warning: 0.75,
          alert: 0.95,
          error: 1
        }.freeze
        usage_ratio = root_storage_size.usage_ratio
        current_level = usage_thresholds.each_key.first

        usage_thresholds.each do |level, threshold|
          current_level = level if usage_ratio >= threshold
        end

        current_level
      end

      def user_has_access?
        # Requires owner_access only for users accessing Personal Namespaces
        if !context.is_a?(Project) && context.user_namespace?
          Ability.allowed?(user, :owner_access, context)
        else
          Ability.allowed?(user, :guest_access, context)
        end
      end

      def namespace_has_additional_storage_purchased?
        root_namespace.additional_purchased_storage_size > 0
      end

      def user_has_dismissed_alert?
        if root_namespace.user_namespace?
          user.dismissed_callout?(feature_name: callout_feature_name)
        else
          user.dismissed_callout_for_group?(
            feature_name: callout_feature_name,
            group: root_namespace
          )
        end
      end

      def show_purchase_link?
        return false unless ::Gitlab::CurrentSettings.automatic_purchased_storage_allocation?

        Ability.allowed?(user, :owner_access, root_namespace)
      end

      def free_tier_alert_title
        text_args = {
          namespace_name: root_namespace.name,
          free_size_limit: formatted(root_namespace.actual_size_limit)
        }

        s_(
          "NamespaceStorageSize|You have reached the free storage limit of %{free_size_limit} for %{namespace_name}"
        ) % text_args
      end

      def usage_percentage_alert_title
        text_args = {
          usage_in_percent: usage_in_percent,
          namespace_name: root_namespace.name,
          used_storage: formatted(root_storage_size.current_size),
          storage_limit: formatted(root_storage_size.limit)
        }

        s_(
          "NamespaceStorageSize|You have used %{usage_in_percent} of the storage quota for %{namespace_name} " \
          "(%{used_storage} of %{storage_limit})"
        ) % text_args
      end

      def alert_message_explanation
        text_args = {
          namespace_name: root_namespace.name,
          read_only_link_start: link_start_tag(help_page_path('user/read_only_namespaces')),
          link_end: "</a>"
        }

        if root_storage_size.above_size_limit?
          Kernel.format(
            s_(
              "NamespaceStorageSize|%{namespace_name} is now read-only. Your ability to write new data to " \
              "this namespace is restricted. %{read_only_link_start}Which actions are restricted?%{link_end}"
            ),
            text_args
          ).html_safe
        else
          Kernel.format(
            s_(
              "NamespaceStorageSize|If %{namespace_name} exceeds the storage quota, your ability to " \
              "write new data to this namespace will be restricted. " \
              "%{read_only_link_start}Which actions become restricted?%{link_end}"
            ),
            text_args
          ).html_safe
        end
      end

      def alert_message_cta
        text_args = {
          manage_storage_link_start: link_start_tag(
            help_page_path('user/usage_quotas', anchor: 'manage-your-storage-usage')
          ),
          group_member_link_start: link_start_tag(group_group_members_path(root_namespace)),
          purchase_more_link_start: link_start_tag(
            help_page_path('subscriptions/gitlab_com/index.md', anchor: 'purchase-more-storage-and-transfer')
          ),
          link_end: "</a>"
        }

        if root_storage_size.above_size_limit?
          if Ability.allowed?(user, :owner_access, context)
            return Kernel.format(
              s_(
                "NamespaceStorageSize|To remove the read-only state " \
                "%{manage_storage_link_start}manage your storage usage%{link_end}, " \
                "or %{purchase_more_link_start}purchase more storage%{link_end}."
              ),
              text_args
            ).html_safe
          end

          Kernel.format(
            s_(
              "NamespaceStorageSize|To remove the read-only state " \
              "%{manage_storage_link_start}manage your storage usage%{link_end}, " \
              "or contact a user with the %{group_member_link_start}owner role for this namespace%{link_end} " \
              "and ask them to %{purchase_more_link_start}purchase more storage%{link_end}."
            ),
            text_args
          ).html_safe
        else
          if Ability.allowed?(user, :owner_access, context)
            return Kernel.format(
              s_(
                "NamespaceStorageSize|To prevent your projects from being in a read-only state " \
                "%{manage_storage_link_start}manage your storage usage%{link_end}, " \
                "or %{purchase_more_link_start}purchase more storage%{link_end}."
              ),
              text_args
            ).html_safe
          end

          Kernel.format(
            s_(
              "NamespaceStorageSize|To prevent your projects from being in a read-only state " \
              "%{manage_storage_link_start}manage your storage usage%{link_end}, " \
              "or contact a user with the %{group_member_link_start}owner role for this namespace%{link_end} " \
              "and ask them to %{purchase_more_link_start}purchase more storage%{link_end}."
            ),
            text_args
          ).html_safe
        end
      end

      def alert_message_faq
        text_args = {
          faq_link_start: link_start_tag(
            "#{promo_url}/pricing/#what-happens-if-i-exceed-my-storage-and-transfer-limits"
          ),
          link_end: "</a>"
        }

        Kernel.format(
          s_(
            "NamespaceStorageSize|For more information about storage limits, see our %{faq_link_start}FAQ%{link_end}."
          ),
          text_args
        ).html_safe
      end

      def link_start_tag(url)
        "<a href='#{url}' target='_blank' rel='noopener noreferrer'>"
      end

      def formatted(number)
        number_to_human_size(number, delimiter: ',', precision: 2)
      end

      def usage_in_percent
        number_to_percentage(root_storage_size.usage_ratio * 100, precision: 0)
      end
    end
  end
end
