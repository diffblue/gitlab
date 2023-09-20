# frozen_string_literal: true

module EE
  module API
    module Helpers
      module InternalHelpers
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        override :access_checker_for
        def access_checker_for(actor, protocol)
          super.tap do |checker|
            checker.allowed_namespace_path = params[:namespace_path]
          end
        end

        # rubocop:disable Gitlab/ModuleWithInstanceVariables
        override :send_git_audit_streaming_event
        def send_git_audit_streaming_event(msg)
          ::Gitlab::GitAuditEvent.new(actor, project).send_audit_event(msg)
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end
