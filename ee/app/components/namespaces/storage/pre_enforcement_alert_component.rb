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
        return false unless ::EE::Gitlab::Namespaces::Storage::Enforcement.show_pre_enforcement_banner?(root_namespace)

        !dismissed?
      end

      private

      delegate :storage_counter, to: :helpers
      attr_reader :context, :root_namespace, :user

      def content_class
        "container-limited limit-container-width" unless user.layout == "fluid"
      end

      def rollout_docs_link
        help_page_path('user/usage_quotas', anchor: 'namespace-storage-limit-enforcement-schedule')
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
          storage_enforcement_date: root_namespace.storage_enforcement_date,
          namespace_name: root_namespace.name,
          extra_message: paragraph_1_extra_message,
          rollout_link_start: Kernel.format('<a href="%{url}" >', { url: rollout_docs_link }),
          link_end: "</a>"
        }.merge(strong_tags)

        Kernel.format(
          s_(
            "UsageQuota|Effective %{storage_enforcement_date}, namespace storage limits will apply " \
            "to the %{strong_start}%{namespace_name}%{strong_end} namespace. %{extra_message}" \
            "View the %{rollout_link_start}rollout schedule for this change%{link_end}."
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
            "%{docs_link_start}Learn more%{link_end}." \
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
          s_("UsageQuota|See our %{faq_link_start}FAQ%{link_end} for more information."),
          text_args
        ).html_safe
      end

      def user_allowed?
        Ability.allowed?(user, :maintainer_access, context)
      end

      def callout_threshold
        days_to_enforcement_date = (root_namespace.storage_enforcement_date - Date.today)

        return :first if days_to_enforcement_date > 30
        return :second if days_to_enforcement_date > 15 && days_to_enforcement_date <= 30
        return :third if days_to_enforcement_date > 7 && days_to_enforcement_date <= 15
        return :fourth if days_to_enforcement_date >= 0 && days_to_enforcement_date <= 7
      end

      def callout_feature_name
        "storage_enforcement_banner_#{callout_threshold}_enforcement_threshold"
      end

      def callout_data
        {
          feature_id: callout_feature_name,
          dismiss_endpoint: root_namespace.user_namespace? ? namespace_callouts_path : group_callouts_path,
          defer_links: "true"
        }.merge(
          root_namespace.user_namespace? ? { namespace_id: root_namespace_id } : { group_id: root_namespace_id }
        )
      end

      def root_namespace_id
        root_namespace.id
      end

      def dismissed?
        user.dismissed_callout_for_group?(
          feature_name: callout_feature_name,
          group: root_namespace
        )
      end
    end
  end
end
