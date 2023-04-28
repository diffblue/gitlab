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
        return super unless user_namespace?

        # This callout is used when user A is viewing a project that belongs to a User B
        # i.e. User B Namespace owns the project, and user A is a maintainer on given project
        # We can't use Users::Callout because we'd dismiss user A Namespace alert
        # So we rely on Users::ProjectCallout for proper dismissal without side effects
        user.dismissed_callout_for_project?(
          **dismissed_callout_args,
          project: context
        )
      end

      def extra_callout_data
        return super unless user_namespace?

        # In this context we rely on Users::ProjectCallout for proper dismissal without side effects
        { project_id: context.id }
      end

      def dismiss_endpoint
        return super unless user_namespace?

        # In this context we rely on Users::ProjectCallout for proper dismissal without side effects
        project_callouts_path
      end

      def user_namespace?
        root_namespace.user_namespace?
      end
    end
  end
end
