# frozen_string_literal: true

module EE
  module Issuable
    module DestroyService
      extend ::Gitlab::Utils::Override

      private

      override :after_destroy
      def after_destroy(issuable)
        log_audit_event(issuable)
        track_usage_ping_epic_destroyed(issuable) if issuable.is_a?(Epic)

        super
      end

      override :group_for
      def group_for(issuable)
        return issuable.resource_parent if issuable.is_a?(Epic)

        super
      end

      def track_usage_ping_epic_destroyed(epic)
        ::Gitlab::UsageDataCounters::EpicActivityUniqueCounter.track_epic_destroyed(
          author: current_user,
          namespace: epic.group
        )
      end

      def log_audit_event(issuable)
        return unless current_user

        if issuable.is_a?(MergeRequest)
          ::Audit::MergeRequestDestroyAuditor.new(issuable, current_user).execute
        else
          issuable_name = issuable.is_a?(Issue) ? issuable.work_item_type.name : issuable.class.name

          audit_context = {
            name: "delete_#{issuable.to_ability_name}",
            stream_only: true,
            author: current_user,
            target: issuable,
            scope: issuable.resource_parent,
            message: "Removed #{issuable_name}(#{issuable.title} with IID: #{issuable.iid} and ID: #{issuable.id})",
            target_details: { title: issuable.title, iid: issuable.iid, id: issuable.id, type: issuable_name }
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end
    end
  end
end
