# frozen_string_literal: true

module EE
  module DeployKeys
    module CreateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(project: nil)
        super.tap do |key|
          if project && key.persisted?
            log_audit_event(key, project)
          end
        end
      end

      private

      def log_audit_event(key, project)
        audit_context = {
          name: 'deploy_key_added',
          author: user,
          scope: project,
          target: key,
          message: "Added deploy key",
          additional_details: { add: "deploy_key" }
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
