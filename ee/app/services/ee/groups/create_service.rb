# frozen_string_literal: true

module EE
  module Groups
    module CreateService
      extend ::Gitlab::Utils::Override

      AUDIT_EVENT_TYPE = 'group_created'
      AUDIT_EVENT_MESSAGE = 'Added group'

      override :execute
      def execute
        super.tap do |group|
          next unless group&.persisted?

          log_audit_event
        end
      end

      private

      override :after_build_hook
      def after_build_hook(group, params)
        # Repository size limit comes as MB from the view
        limit = params.delete(:repository_size_limit)
        group.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit
      end

      override :after_create_hook
      def after_create_hook
        super

        group.persisted? &&
          create_event &&
          ::Groups::CreateEventWorker.perform_async(group.id, current_user.id, :created)
      end

      override :remove_unallowed_params
      def remove_unallowed_params
        unless current_user&.admin?
          params.delete(:shared_runners_minutes_limit)
          params.delete(:extra_shared_runners_minutes_limit)
          params.delete(:delayed_project_removal)
        end

        super
      end

      def log_audit_event
        audit_context = {
          name: AUDIT_EVENT_TYPE,
          author: current_user,
          scope: group,
          target: group,
          message: AUDIT_EVENT_MESSAGE,
          target_details: group.full_path
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
