# frozen_string_literal: true

module EE
  module Projects
    module GroupLinks
      module UpdateService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute(group_link_params)
          super

          project_stream_audit_event(group_link)
        end

        private

        def project_stream_audit_event(group_link)
          audit_context = {
            name: 'project_group_link_update',
            stream_only: true,
            author: current_user,
            scope: project,
            target: group_link.group,
            message: audit_message(group_link)
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end

        def audit_message(group_link)
          changes = []

          if group_link.saved_changes['group_access'].present?
            old_value, new_value = group_link.saved_changes['group_access'].map { |v| ::Gitlab::Access.human_access(v) }
            property = :group_access
            changes << "profile #{property} from #{old_value} to #{new_value}"
          end

          if group_link.saved_changes['expires_at'].present?
            old_value, new_value = group_link.saved_changes['expires_at']
            property = :expires_at
            changes << "profile #{property} from #{old_value || 'nil'} to #{new_value || 'nil'}"
          end

          "Changed project group link #{changes.join(' ')}"
        end
      end
    end
  end
end
