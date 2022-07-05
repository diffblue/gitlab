# frozen_string_literal: true

module EE
  module Ci
    module Runners
      # Unregisters a CI Runner and logs an audit event
      #
      module UnregisterRunnerService
        extend ::Gitlab::Utils::Override
        include ::Audit::Changes

        override :execute
        def execute
          scopes = runner_scopes # Save the scopes before destroying the record

          result = super

          audit_event(scopes)

          result
        end

        private

        def runner_scopes
          case runner.runner_type
          when 'instance_type'
            [nil]
          when 'group_type'
            runner.groups.to_a
          when 'project_type'
            runner.projects.to_a
          end
        end

        def audit_event(scopes)
          scopes.each do |scope|
            ::AuditEvents::UnregisterRunnerAuditEventService.new(runner, author, scope)
              .track_event
          end
        end
      end
    end
  end
end
