# frozen_string_literal: true

module EE
  module API
    module Helpers
      module InternalHelpers
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        override :send_git_audit_streaming_event
        def send_git_audit_streaming_event(msg)
          return if actor.user.blank? || @project.blank?

          audit_context = {
            name: 'repository_git_operation',
            stream_only: true,
            author: actor.deploy_key_or_user,
            scope: @project,
            target: @project,
            message: msg
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end
