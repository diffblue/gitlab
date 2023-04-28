# frozen_string_literal: true

module Namespaces
  module Storage
    class UserPreEnforcementAlertComponent < ::Namespaces::Storage::PreEnforcementAlertComponent
      private

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
            "of namespace storage. View and manage your usage from " \
            "%{strong_start}%{usage_quotas_nav_instruction}%{strong_end}. " \
            "%{docs_link_start}Learn more%{link_end} about how to reduce your storage." \
          ),
          text_args
        ).html_safe
      end

      def user_allowed?
        Ability.allowed?(user, :owner_access, context)
      end

      def dismissed?
        user.dismissed_callout?(**dismissed_callout_args)
      end

      def dismiss_endpoint
        callouts_path
      end

      def extra_callout_data
        {}
      end
    end
  end
end
