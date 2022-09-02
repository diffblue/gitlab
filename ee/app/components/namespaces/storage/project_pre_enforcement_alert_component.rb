# frozen_string_literal: true

module Namespaces
  module Storage
    class ProjectPreEnforcementAlertComponent < ::Namespaces::Storage::PreEnforcementAlertComponent
      private

      def paragraph_1_extra_message
        Kernel.format(
          s_("UsageQuota|The %{strong_start}%{context_name}%{strong_end} project will be affected by this. "),
          strong_tags.merge(context_name: context.name)
        )
      end

      def dismissed?
        if root_namespace.user_namespace?
          user.dismissed_callout_for_namespace?(
            feature_name: callout_feature_name,
            namespace: root_namespace
          )
        else
          user.dismissed_callout_for_group?(
            feature_name: callout_feature_name,
            group: root_namespace
          )
        end
      end
    end
  end
end
