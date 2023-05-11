# frozen_string_literal: true

module Namespaces
  module Storage
    class PreEnforcementAlertComponent < ViewComponent::Base
      # @param [UserNamespace, Group, SubGroup, Project] context
      # @param [User] user
      def initialize(context:, user:)
        @context = context
        @root_namespace = context.root_ancestor
        @user = user
      end

      def render?
        return false unless user_allowed?
        return false unless ::Namespaces::Storage::Enforcement.show_pre_enforcement_alert?(root_namespace)

        !dismissed?
      end

      private

      delegate :storage_counter, to: :helpers
      attr_reader :context, :root_namespace, :user

      def dismissible?
        !root_namespace.over_storage_limit?
      end

      def content_class
        "container-limited limit-container-width" unless user.layout == "fluid"
      end

      def storage_limit_docs_link
        help_page_path('user/usage_quotas', anchor: 'namespace-storage-limit')
      end

      def learn_more_link
        help_page_path('user/usage_quotas', anchor: 'manage-your-storage-usage')
      end

      def faq_link
        "#{Gitlab::Saas.about_pricing_url}faq-efficient-free-tier/#storage-limits-on-gitlab-saas-free-tier"
      end

      def strong_tags
        {
          strong_start: "<strong>",
          strong_end: "</strong>"
        }
      end

      def paragraph_1_extra_message
        ''
      end

      def text_paragraph_1
        text_args = {
          namespace_name: root_namespace.name,
          extra_message: paragraph_1_extra_message,
          storage_limit_link_start: Kernel.format('<a href="%{url}" >', { url: storage_limit_docs_link }),
          link_end: "</a>"
        }.merge(strong_tags)

        Kernel.format(
          s_(
            "UsageQuota|%{storage_limit_link_start}A namespace storage limit%{link_end} will soon " \
            "be enforced for the %{strong_start}%{namespace_name}%{strong_end} namespace. %{extra_message}"
          ),
          text_args
        ).html_safe
      end

      def usage_quotas_nav_instruction
        if root_namespace.user_namespace?
          s_("UsageQuota|User settings &gt; Usage quotas")
        else
          s_("UsageQuota|Group settings &gt; Usage quotas")
        end
      end

      def text_paragraph_2
        text_args = {
          used_storage: storage_counter(root_namespace.root_storage_statistics&.storage_size || 0),
          usage_quotas_nav_instruction: usage_quotas_nav_instruction,
          docs_link_start: Kernel.format('<a href="%{url}" >', { url: learn_more_link }),
          link_end: "</a>"
        }.merge(strong_tags)

        Kernel.format(
          s_(
            "UsageQuota|The namespace is currently using %{strong_start}%{used_storage}%{strong_end} "\
            "of namespace storage. Group owners can view namespace storage usage and purchase more from " \
            "%{strong_start}%{usage_quotas_nav_instruction}%{strong_end}. " \
            "%{docs_link_start}How can I manage my storage?%{link_end}." \
          ),
          text_args
        ).html_safe
      end

      def text_paragraph_3
        text_args = {
          faq_link_start: Kernel.format('<a href="%{url}" >', { url: faq_link }),
          link_end: "</a>"
        }

        Kernel.format(
          s_("UsageQuota|For more information about storage limits, see our %{faq_link_start}FAQ%{link_end}."),
          text_args
        ).html_safe
      end

      def user_allowed?
        Ability.allowed?(user, :guest_access, context)
      end

      def callout_feature_name
        "namespace_storage_pre_enforcement_banner"
      end

      def callout_data
        {
          **extra_callout_data,
          feature_id: callout_feature_name,
          dismiss_endpoint: dismiss_endpoint,
          defer_links: "true"
        }
      end

      def extra_callout_data
        { group_id: root_namespace.id }
      end

      def dismiss_endpoint
        group_callouts_path
      end

      def dismissed_callout_args
        {
          feature_name: callout_feature_name,
          ignore_dismissal_earlier_than: 14.days.ago
        }
      end

      def dismissed?
        user.dismissed_callout_for_group?(
          **dismissed_callout_args,
          group: root_namespace
        )
      end
    end
  end
end
