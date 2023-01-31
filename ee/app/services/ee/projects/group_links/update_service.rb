# frozen_string_literal: true

module EE
  module Projects
    module GroupLinks
      module UpdateService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute(group_link_params)
          super

          send_audit_event
        end

        private

        def send_audit_event
          return unless saved_changes_present?

          message, details = audit_message

          audit_context = {
            name: 'project_group_link_updated',
            author: current_user,
            scope: project,
            target: group_link.group,
            message: message,
            additional_details: details
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end

        def saved_changes_present?
          group_link.saved_changes['group_access'].present? || group_link.saved_changes['expires_at'].present?
        end

        def audit_message
          changes = []
          details = { change: {} }

          if group_link.saved_changes['group_access'].present?
            old_value, new_value = group_link.saved_changes['group_access'].map { |v| ::Gitlab::Access.human_access(v) }
            property = :group_access
            changes << "profile #{property} from #{old_value} to #{new_value}"
            details[:change].update({ access_level: { from: old_value, to: new_value } })
          end

          if group_link.saved_changes['expires_at'].present?
            old_value, new_value = group_link.saved_changes['expires_at']
            property = :expires_at
            changes << "profile #{property} from #{old_value || 'nil'} to #{new_value || 'nil'}"
            details[:change].update({ invite_expiry: { from: old_value || 'nil', to: new_value || 'nil' } })
          end

          ["Changed project group link #{changes.join(' ')}", details]
        end
      end
    end
  end
end
